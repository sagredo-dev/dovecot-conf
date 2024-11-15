#!/bin/bash
#
# Updates the vpopmail.lastauth table on login
# Thanks kengheng for the hint
#
# example for 10-master.conf:
#
# service imap {
#  executable = imap postlogin
# }
#
#service pop3 {
#  executable = pop3 postlogin
#}
#service postlogin {
#  executable = script-login /usr/local/dovecot/etc/dovecot_postlogin.sh
#  user = $default_login_user
#  unix_listener postlogin {
#    user = vpopmail
#    group = vchkpw
#    mode = 0660
#  }
#}

set -e

VPOPMAILDIR=$(getent passwd vpopmail | cut -d: -f6)
if [ ! -d $VPOPMAILDIR ]; then
  echo "${VPOPMAILDIR} dir not found"
  exit 1
fi

# Config and executables path
VPOPMAIL_MYSQL_CONFIG="${VPOPMAILDIR}/etc/vpopmail.mysql"

if [ ! -r $VPOPMAIL_MYSQL_CONFIG ]; then
  echo "${VPOPMAIL_MYSQL_CONFIG} file not found"
  exit 1
fi

# Extract mysql params
HOST=$(sed -n "/#/! s/^\(.*\)|.*|.*|.*|.*/\1/p" $VPOPMAIL_MYSQL_CONFIG)
PORT=$(sed -n "/#/! s/^.*|\(.*\)|.*|.*|.*/\1/p" $VPOPMAIL_MYSQL_CONFIG)
 USR=$(sed -n "/#/! s/^.*|.*|\(.*\)|.*|.*/\1/p" $VPOPMAIL_MYSQL_CONFIG)
 PWD=$(sed -n "/#/! s/^.*|.*|.*|\(.*\)|.*/\1/p" $VPOPMAIL_MYSQL_CONFIG)
  DB=$(sed -n "/#/! s/^.*|.*|.*|.*|\(.*\)/\1/p" $VPOPMAIL_MYSQL_CONFIG)

# Split the email into user and domain
u=$(echo $USER | cut -d'@' -f1)
d=$(echo $USER | cut -d'@' -f2)

# Run the query
echo "UPDATE lastauth SET timestamp=UNIX_TIMESTAMP(now()) WHERE user='$u' and domain='$d';" | mysql -P$PORT -h$HOST -u$USR -p$PWD $DB

exec "$@"
