Yii Framework - PHP framework
=============================

`Yii`_ is a high-performance PHP framework best for developing Web
2.0 applications. Yii comes with a rich feature set including MVC,
DAO/ActiveRecord, I18N/L10N, caching, authentication and role-based
access control, scaffolding and testing units. It can reduce your
development time significantly.

This appliance includes all the standard features in `TurnKey Core`_,
and on top of that:

- Yii Framework configurations:
   
   - Installed from upstream source code to /var/www/yiiframework
   - Symlink to yiic CLI command in path (convenience).

- SSL support out of the box.
- `Adminer`_ administration frontend for MySQL (listening on port
  12322 - uses SSL).
- Postfix MTA (bound to localhost) to allow sending of email (e.g.,
  password recovery).
- Webmin modules for configuring Apache2, PHP, MySQL and Postfix.

Credentials *(passwords set at first boot)*
-------------------------------------------

-  Webmin, SSH, MySQL, phpMyAdmin: username **root**


.. _Yii: http://www.yiiframework.com
.. _TurnKey Core: http://www.turnkeylinux.org/core
.. _Adminer: http://www.adminer.org/
