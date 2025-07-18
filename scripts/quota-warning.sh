#!/bin/sh
#
# Send the quota warning message
# Author: R. Puzzanghera https://www.sagredo.eu
#
# Runned by 90-quota.conf
#
# usage: ./quota-warning.sh 95 overquotauser@mydomain.tld
#
# Set the file quota-warning.conf (unless en language is ok for you)
# and eventually add a translation in the tpl dir.

# Configuration file for the script (optional)
CONF_FILE="$(dirname $0)/$(basename $0 .sh).conf"
[ -f ${CONF_FILE} ] && . ${CONF_FILE}

# Template language (default is en)
TPL_LANG=${TPL_LANG:-en}

# The message template which will be used to draft the email
if [ $1 -ge 100 ]; then
  MSG_TEMPLATE="$(dirname $0)/tpl/quota-over.$TPL_LANG.tpl"
else
  MSG_TEMPLATE="$(dirname $0)/tpl/quota-warning.$TPL_LANG.tpl"
fi

# From email addresses
if [ -z "$FROM_EMAIL" ]; then
  # If FROM_EMAIL is not defined in the config file, try to define it as noreply@me
  # Try to guess the qmail dir
  QMAIL_DIR=${QMAIL_DIR:-/var/qmail}
  # From host will be control/me
  FROM_HOST=`cat $QMAIL_DIR/control/me`
  if [ ! -f $QMAIL_DIR/control/me ]; then
    echo "** Cannot find the $QMAIL_DIR/control/me file!"
    echo "** Please add QMAIL_DIR or FROM_EMAIL in $CONF_FILE"
    echo "** Aborting..."
    exit 1
  else FROM_EMAIL="noreply@$FROM_HOST"
  fi
fi

if [ ! -f "$MSG_TEMPLATE" ]; then
  echo "** Cannot find mail message template $MSG_TEMPLATE!"
  echo "** You may check the TPL_LANG variable."
  echo "** Aborting..."
  exit 1
fi

# quota_enforce=no to get the warning stored into inbox even when the mailbox is full
cat $MSG_TEMPLATE \
    | sed -e "s,@PERCENTAGE@,$1,g" \
          -e "s,@FROM_EMAIL@,$FROM_EMAIL,g" \
          -e "s,@USER@,$2,g" \
    | $(dirname $0)/../../libexec/dovecot/dovecot-lda -d $2 -o quota_enforce=no

exit 0
