#!/usr/bin/python
"""Set Yii Framework Gii password and admin email

Option:
    --pass=     unless provided, will ask interactively
    --email=    unless provided, will ask interactively

"""

import sys
import getopt

from dialog_wrapper import Dialog
from executil import system

def usage(s=None):
    if s:
        print >> sys.stderr, "Error:", s
    print >> sys.stderr, "Syntax: %s [options]" % sys.argv[0]
    print >> sys.stderr, __doc__
    sys.exit(1)

def main():
    try:
        opts, args = getopt.gnu_getopt(sys.argv[1:], "h",
                                       ['help', 'pass=', 'email='])
    except getopt.GetoptError, e:
        usage(e)

    password = ""
    email = ""
    for opt, val in opts:
        if opt in ('-h', '--help'):
            usage()
        elif opt == '--pass':
            password = val
        elif opt == '--email':
            email = val

    if not password:
        d = Dialog('TurnKey Linux - First boot configuration')
        password = d.get_password(
            "Yii Framework Password",
            "Enter new password for Gii access.")

    if not email:
        if 'd' not in locals():
            d = Dialog('TurnKey Linux - First boot configuration')

        email = d.get_email(
            "Yii Framework Email",
            "Enter email address for the Yii Framework admin.",
            "admin@example.com")

    config = "/var/www/yiiframework/protected/config/main.php"
    system("sed -i \"s|'password'=>.*|'password'=>'%s',|\" %s" % (password, config))
    system("sed -i \"s|'adminEmail'=>.*|'adminEmail'=>'%s',|\" %s" % (email, config))

if __name__ == "__main__":
    main()

