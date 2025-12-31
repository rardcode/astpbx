#!/bin/bash
set -x

: ${path_list:="
/var/lib/asterisk
/var/spool/asterisk
/var/spool/cron/crontabs
/home/asterisk
/var/log
/var/www/html
/etc/asterisk
/etc/freepbx.conf
"}

DEST_PATH="/data"

function check_dirs {
[ -e "${DEST_PATH}/.pbx_first_installation" ] && rm "${DEST_PATH}/.pbx_first_installation"
echo "--------------------------------------"
echo " Moving persistent data in $DEST_PATH "
echo "--------------------------------------"

for path_name in $path_list; do
 if [ -e ${path_name} ]; then
  if [ ! -e ${DEST_PATH}${path_name} ]; then
    if [ -d $path_name ]; then
      rsync -Ra ${path_name}/ ${DEST_PATH}/
    else
      rsync -Ra ${path_name} ${DEST_PATH}/
    fi
  else
    echo "---------------------------------------------------------"
    echo " No NEED to move anything for $path_name in ${DEST_PATH} "
    echo "---------------------------------------------------------"
  fi
 rm -rf ${path_name}
 fi
 ln -s ${DEST_PATH}${path_name} ${path_name}
done
}

function check_freepbx {
echo "-----------------------------------------"
echo "       FreePBX check ..."
echo "-----------------------------------------"
if [ ! -e ${DEST_PATH}/.pbx_initialized ]; then
  echo ".. FreePBX need to be installed..."
  freepbx_install
else
  ./usr/local/src/freepbx/start_asterisk start
  FREEPBX_VER=$(echo $FREEPBX_VER | cut -d . -f1)
  FREEPBX_VER_INSTALLED="$(/data/var/lib/asterisk/bin/fwconsole -V | awk '{print $NF}' | awk -F'.' '{print $1}')"
  if [ $FREEPBX_VER_INSTALLED -lt $FREEPBX_VER ]; then
   echo ".. FreePBX need to be upgraded..."
   freepbx_upgrade
  else
   echo ".. FreePBX DON'T need to be upgraded..."
  fi
fi
}

function freepbx_install {
echo "-----------------------------------------"
echo "         FreePBX INSTALLATION ..."
echo "-----------------------------------------"

echo "[client]
ssl=0" > /root/.my.cnf

myn=1 ; myt=10
until [ $myn -eq $myt ]; do
  mysql -h 127.0.0.1 -P 3306 -u root --password=${MYSQL_ROOT_PASSWORD} -N -B -e "SELECT 1;" >/dev/null
  RETVAL=$?
    if [ $RETVAL = 0 ]; then
      myn=$myt
    else
      let myn+=1
      echo "--> WARNING: i cannot reach MYSQL db, attempt:[$myn/$myt]"
      sleep 10
    fi
done

if [ ! -e ${DEST_PATH}/.db_initialized ]; then
  echo "Initializing DB..."
  mariadb -h 127.0.0.1 -P 3306 -u root --password=${MYSQL_ROOT_PASSWORD} -N -B -e "CREATE USER IF NOT EXISTS 'asterisk'@'%' IDENTIFIED BY 'asteriskpass';"
  mariadb -h 127.0.0.1 -P 3306 -u root --password=${MYSQL_ROOT_PASSWORD} -N -B -e "CREATE DATABASE IF NOT EXISTS asterisk"
  mariadb -h 127.0.0.1 -P 3306 -u root --password=${MYSQL_ROOT_PASSWORD} -N -B -e "GRANT ALL PRIVILEGES ON asterisk.* TO 'asterisk'@'%' WITH GRANT OPTION;"
  mariadb -h 127.0.0.1 -P 3306 -u root --password=${MYSQL_ROOT_PASSWORD} -N -B -e "CREATE DATABASE IF NOT EXISTS asteriskcdrdb"
  mariadb -h 127.0.0.1 -P 3306 -u root --password=${MYSQL_ROOT_PASSWORD} -N -B -e "GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO 'asterisk'@'%' WITH GRANT OPTION;"
  touch ${DEST_PATH}/.db_initialized
else
  echo "--> INFO: DB initializing skipped."
fi

echo "---------- Freepbx INSTALLATION ----------"
cd /usr/local/src/freepbx

mkdir -p /var/lib/asterisk/sbin/
ln -s /usr/local/src/freepbx/amp_conf/bin/fwconsole /usr/local/bin/
ln -s /usr/local/src/freepbx/amp_conf/bin/fwconsole /var/lib/asterisk/sbin/
ln -s /usr/local/src/freepbx/amp_conf/bin/amportal  /usr/local/bin/
chown -R asterisk: /var/lib/asterisk

./start_asterisk start

./install -n --skip-install --no-ansi --dbhost=127.0.0.1 --dbport=3306 --dbuser=asterisk --dbpass=asteriskpass --dbname=asterisk --cdrdbname=asteriskcdrdb \
 --webroot="/var/www/html" --astetcdir="/etc/asterisk" --astvarlibdir="/var/lib/asterisk" --astagidir="/var/lib/asterisk/agi-bin" --astspooldir="/var/spool/asterisk" \
 --astrundir="/var/run/asterisk" --astlogdir="/var/log/asterisk" --ampbin="/var/lib/asterisk/bin" --ampsbin="/var/lib/asterisk/sbin" --ampcgibin="/var/www/cgi-bin" \
 --ampplayback="/var/lib/asterisk/playback" --astmoddir="/usr/lib64/asterisk/modules"

fwconsole chown

fwconsole ma refreshsignatures
fwconsole ma enablerepo extended
fwconsole ma enablerepo unsupported

: ${PBX_MODULES_CORE:="
framework
core
dashboard
sipsettings
voicemail
"}

: ${PBX_MODULES_PRE:="
userman
pm2
"}

: ${PBX_MODULES_EXTRA:="
soundlang
callrecording
cdr
conferences
customappsreg
featurecodeadmin
infoservices
logfiles
music
manager
arimanager
filestore
recordings
announcement
asteriskinfo
backup
callforward
callwaiting
daynight
calendar
certman
cidlookup
contactmanager
donotdisturb
fax
findmefollow
iaxsettings
miscapps
miscdests
ivr
parking
phonebook
presencestate
printextensions
queues
cel
timeconditions
bulkhandler
weakpasswords
ucp
"}

echo "---------- Modules DOWNLOAD ----------"
for module in ${PBX_MODULES_CORE}; do fwconsole ma download $module ; done
for module in ${PBX_MODULES_PRE}; do fwconsole ma download $module ; done
for module in ${PBX_MODULES_EXTRA}; do fwconsole ma download $module ; done

echo "---------- Modules INSTALLATION ----------"
for module in ${PBX_MODULES_CORE}; do fwconsole ma install $module ; done

fwconsole ma upgradeall

for module in ${PBX_MODULES_PRE}; do fwconsole ma install $module ; done
for module in ${PBX_MODULES_EXTRA}; do fwconsole ma install $module ; done

fwconsole reload
fwconsole -V > "${DEST_PATH}/.pbx_initialized"
fwconsole -V > "${DEST_PATH}/.pbx_first_installation"

fwconsole chown
fwconsole reload
fwconsole stop
}

function freepbx_upgrade {
echo "-----------------------------------------"
echo "       FreePBX UPGRADING..."
echo "-----------------------------------------"
fwconsole start
fwconsole ma upgradeall
fwconsole chown
fwconsole reload
fwconsole ma downloadinstall versionupgrade
fwconsole reload
fwconsole versionupgrade --check
fwconsole versionupgrade --upgrade
fwconsole chown
fwconsole reload
fwconsole ma upgradeall
fwconsole chown
fwconsole reload
fwconsole stop
}

function fix_permissions {
echo "-----------------------------------------"
echo "  Permissions FIXING..."
echo "-----------------------------------------"
touch /var/log/asterisk/freepbx_security.log
chown -R asterisk: /var/spool/asterisk/
chown -R asterisk: /var/lib/asterisk/
chown -R asterisk: /var/log/asterisk/
chown -R asterisk: /var/www/html/
chown -R asterisk: /etc/asterisk/
[ -e /home/asterisk ] && chown -R asterisk: /home/asterisk/
chown -R asterisk: /etc/freepbx.conf
[ ! -e /etc/amportal.conf ] && touch /etc/amportal.conf && chmod 0660 /etc/amportal.conf
chown -R asterisk: /etc/amportal.conf
}

function service_asterisk {
echo "-----------------------------------------"
echo "      Asterisk setup..."
echo "-----------------------------------------"
[ ! -e /usr/bin/fwconsole ] && ln -s /var/lib/asterisk/bin/fwconsole /usr/bin/fwconsole
[ ! -e /usr/bin/amportal ] && ln -s /var/lib/asterisk/bin/amportal /usr/bin/amportal
/usr/local/src/freepbx/start_asterisk start
fwconsole chown
fwconsole reload
}

function service_postfix {
echo "-----------------------------------------"
echo "        Postfix setup..."
echo "-----------------------------------------"
DOCKER_HOSTNAME=$(cat /etc/hostname)
## since postfix uses many processes in chroot, it needs the name resolution file in its chroot
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf

## hostname setup
sed -i "s/^myhostname =.*/myhostname = ${DOCKER_HOSTNAME}/g" /etc/postfix/main.cf

## setup external relay for sending mail
if [ ! -z ${POSTFIX_SMTP_SERVER} ]; then
sed -i "s/^relayhost =.*/relayhost = [${POSTFIX_SMTP_SERVER}]:${POSTFIX_SMTP_PORT}/g" /etc/postfix/main.cf
else
sed -i "s/^relayhost =.*/relayhost = /g" /etc/postfix/main.cf
fi

SENDER_DOMAIN=$(echo ${POSTFIX_MAIL_SENDER} | cut -d @ -f2)
echo "address {
  email-domain ${SENDER_DOMAIN};
};" > /etc/mailutils.conf

echo "/.+/  ${POSTFIX_SENDER_MAIL}" > /etc/postfix/sender_canonical
echo "[${POSTFIX_SMTP_SERVER}]:${POSTFIX_SMTP_PORT} ${POSTFIX_SMTP_USER}:${POSTFIX_SMTP_PASSWD}" > /etc/postfix/sasl_passwd

if [ $POSTFIX_SMTP_TLS = OFF ]; then
  sed -i "s/^smtp_use_tls/#smtp_use_tls/g" /etc/postfix/main.cf
  sed -i "s/^smtp_tls_security_level/#smtp_tls_security_level/g" /etc/postfix/main.cf
  sed -i "s/^smtp_sasl_password_maps/#smtp_sasl_password_maps/g" /etc/postfix/main.cf
  sed -i "s/^smtp_sasl_security_options/#smtp_sasl_security_options/g" /etc/postfix/main.cf
  sed -i "s/^smtp_sasl_auth_enable/#smtp_sasl_auth_enable/g" /etc/postfix/main.cf
else
  sed -i "s/^#smtp_use_tls/smtp_use_tls/g" /etc/postfix/main.cf
  sed -i "s/^#smtp_tls_security_level/smtp_tls_security_level/g" /etc/postfix/main.cf
  sed -i "s/^#smtp_sasl_password_maps/smtp_sasl_password_maps/g" /etc/postfix/main.cf
  sed -i "s/^#smtp_sasl_security_options/smtp_sasl_security_options/g" /etc/postfix/main.cf
  sed -i "s/^#smtp_sasl_auth_enable/smtp_sasl_auth_enable/g" /etc/postfix/main.cf
fi

echo "root: ${POSTFIX_RECIPIENT_MAIL}" >> /etc/aliases
newaliases
postmap /etc/postfix/sasl_passwd
}

function service_fail2ban {
echo "-------------------------------"
echo "       Fail2ban setup..."
echo "-------------------------------"
[ ! -e /var/log/fail2ban.log ] && touch /var/log/fail2ban.log

if [ ! -e /etc/logrotate.d/fail2ban ]; then
echo "/var/log/fail2ban.log {
    rotate 12
    yearly
    dateext
    missingok
    compress
    notifempty
    postrotate
      /usr/bin/fail2ban-client flushlogs 1>/dev/null || true
    endscript
}" > /etc/logrotate.d/fail2ban
fi

echo "fail2ban: root" >> /etc/aliases
newaliases
rm /etc/fail2ban/jail.d/defaults-debian.conf

}

function custom_bashrc {
echo '
export LS_OPTIONS="--color=auto"
alias "ls=ls $LS_OPTIONS"
alias "ll=ls $LS_OPTIONS -la"
alias "l=ls $LS_OPTIONS -lA"
'
}

function set_bashrc {
echo "-----------------------------------------"
echo " .bashrc file setup..."
echo "-----------------------------------------"
custom_bashrc | tee /root/.bashrc
echo 'export PS1="\[\e[35m\][\[\e[31m\]\u\[\e[36m\]@\[\e[32m\]\h\[\e[90m\] \w\[\e[35m\]]\[\e[0m\]# "' >> /root/.bashrc
for userhome in $(ls /home); do
[ -e /home/$userhome ] && echo 'export PS1="\[\e[35m\][\[\e[33m\]\u\[\e[36m\]@\[\e[32m\]\h\[\e[90m\] \w\[\e[35m\]]\[\e[0m\]$ "' >> /home/$userhome/.bashrc
done
}

[ -e "${DEST_PATH}/.pbx_initialized" ] && check_dirs
check_freepbx
fix_permissions
service_asterisk
service_postfix
service_fail2ban
set_bashrc
[ -e "${DEST_PATH}/.pbx_first_installation" ] && check_dirs

CMD="$@"
[ -z $CMD ] && export CMD="supervisord -c /etc/supervisor/supervisord.conf"
$CMD
