#!/bin/bash
set -Eeuo pipefail
umask 077
trap 'printf "yiiframework-v19-test: line %s failed\n" "$LINENO" >&2' ERR

result=${TKL_TEST_RESULT:?TKL_TEST_RESULT is required}
db_password=${TKL_TEST_DB_PASS:?TKL_TEST_DB_PASS is required}
webroot=/var/www/yiiframework
source_file=/usr/local/share/turnkey-yiiframework/source
page=$(mktemp /tmp/yiiframework-page.XXXXXXXX)
update=$(mktemp /tmp/yiiframework-update.XXXXXXXX)

cleanup() {
    find "$page" "$update" -maxdepth 0 -delete
}
trap cleanup EXIT

for unit in apache2.service mariadb.service cron.service; do
    systemctl --quiet is-active "$unit"
    systemctl --quiet is-enabled "$unit"
done
apache2ctl configtest
grep -Fxq 'VERSION_CODENAME=trixie' /etc/os-release
grep -Eq '^turnkey-yiiframework-19\.0' /etc/turnkey_version

# shellcheck disable=SC1090
. "$source_file"
test "$version" = 2.0.55
test "$tag" = 2.0.55
test "$commit" = babee66def599432735a1ed39c9cf0bc5163a775
test "$archive_sha256" = e4e74986791b14deb0175685e9c45ebf0809984ae9dd19d284142fb06cbb348a
runtime_version=$(php -r \
    'require "/var/www/yiiframework/vendor/yiisoft/yii2/Yii.php"; echo Yii::getVersion();')
test "$runtime_version" = "$version"
test "$(stat -c '%U:%G:%a' "$webroot/common/config/main-local.php")" = \
    'root:www-data:640'

curl --fail --silent --show-error http://127.0.0.1/ >"$page"
grep -Fq 'successfully launched your TurnKey Linux Yii-powered server' "$page"
curl --insecure --fail --silent --show-error https://127.0.0.1/ >"$page"
grep -Fq 'successfully launched your TurnKey Linux Yii-powered server' "$page"
curl --insecure --fail --silent --show-error https://127.0.0.1/admin/ >"$page"
grep -Fq 'id="login-form"' "$page"
grep -Fq 'name="_csrf-backend"' "$page"

yii help >/dev/null
yii migrate/history 1 |
    grep -Fq 'm190124_110200_add_verification_token_column_to_user_table'
db_value=$(runuser -u www-data -- php -r '
    require "/var/www/yiiframework/vendor/autoload.php";
    require "/var/www/yiiframework/vendor/yiisoft/yii2/Yii.php";
    require "/var/www/yiiframework/common/config/bootstrap.php";
    require "/var/www/yiiframework/console/config/bootstrap.php";
    $config = yii\helpers\ArrayHelper::merge(
        require "/var/www/yiiframework/common/config/main.php",
        require "/var/www/yiiframework/common/config/main-local.php",
        require "/var/www/yiiframework/console/config/main.php",
        require "/var/www/yiiframework/console/config/main-local.php"
    );
    $app = new yii\console\Application($config);
    echo $app->db->createCommand("SELECT COUNT(*) FROM migration WHERE version = :version")
        ->bindValue(":version", "m190124_110200_add_verification_token_column_to_user_table")
        ->queryScalar();
')
test "$db_value" = 1
MYSQL_PWD=$db_password mariadb --user=root --batch --skip-column-names \
    yii2 --execute="SELECT COUNT(*) FROM migration WHERE version = 'm190124_110200_add_verification_token_column_to_user_table'" |
    grep -Fxq 1

yii-update --check >"$update"
latest=$(sed -n 's/^latest=//p' "$update")
candidate=$(sed -n 's/^candidate=//p' "$update")
status=$(sed -n 's/^status=//p' "$update")
asset=$(sed -n 's/^asset=//p' "$update")
[[ $latest =~ ^2\.0\.[0-9]+$ ]]
[[ $candidate =~ ^[0-9a-f]{40}$ ]]
grep -Fxq 'channel=official-yii-2.x' "$update"
curl --fail --location --silent --show-error --head "$asset" >/dev/null

cat >"$result" <<EOF
package_source=official Yii advanced application $tag archive with SHA-256 $archive_sha256
installed_version=Yii $runtime_version on PHP $(php -r 'echo PHP_VERSION;')
runtime_checks=normal init; Apache HTTP and HTTPS frontend; HTTPS backend; Yii console; Yii database component and MariaDB readback
updater_command=yii-update --check
updater_result=$status; target=$latest; candidate=$candidate
updater_channel=official Yii 2.x Git tags and advanced-application release assets
integrity_evidence=release tag commit $commit; archive SHA-256 $archive_sha256
EOF
