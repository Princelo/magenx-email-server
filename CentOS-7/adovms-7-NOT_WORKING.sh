#!/bin/bash
#====================================================================#
#  MagenX - Automated Deployment of Virtual Mail Server              #
#  Copyright (C) 2015 admin@magenx.com                               #
#  All rights reserved.                                              #
#====================================================================#
# version
ADOVMS_VER="3.0.11-3"

# Repositories
REPO_EPEL="http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm"

# Extra packages
POSTFIX="http://repos.oostergo.net/6/postfix-3.0/postfix-3.0.1-1.el6.x86_64.rpm"
MAIL_PACKAGES="dovecot dovecot-pigeonhole clamav-server clamav-data clamav-update clamav-filesystem clamav clamav-scanner-systemd clamav-devel clamav-lib clamav-server-systemd"
EXTRA_PACKAGES="opendkim git subversion "

# Configs
POSTFIX_MAIN_CF="https://raw.githubusercontent.com/magenx/magenx-email-server/master/CentOS-7/main.cf"
DOVECOT_CONF="https://raw.githubusercontent.com/magenx/magenx-email-server/master/CentOS-7/dovecot.conf"
DOVECOT_SQL_CONF="https://raw.githubusercontent.com/magenx/magenx-email-server/master/CentOS-7/dovecot-sql.conf"

# Simple colors
RED="\e[31;40m"
GREEN="\e[32;40m"
YELLOW="\e[33;40m"
WHITE="\e[37;40m"
BLUE="\e[0;34m"

# Background
DGREYBG="\t\t\e[100m"
BLUEBG="\e[44m"
REDBG="\t\t\e[41m"

# Styles
BOLD="\e[1m"

# Reset
RESET="\e[0m"

# quick-n-dirty coloring
function WHITETXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${WHITE}${BOLD}${MESSAGE}${RESET}"
}
function BLUETXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${BLUE}${BOLD}${MESSAGE}${RESET}"
}
function REDTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${RED}${BOLD}${MESSAGE}${RESET}"
} 
function GREENTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${GREEN}${BOLD}${MESSAGE}${RESET}"
}
function YELLOWTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${YELLOW}${BOLD}${MESSAGE}${RESET}"
}
function BLUEBG() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "${BLUEBG}${MESSAGE}${RESET}"
}
function pause() {
   read -p "$*"
}

clear
###################################################################################
#                                     START CHECKS                                #
###################################################################################
echo

# root?
if [[ ${EUID} -ne 0 ]]; then
  echo
  REDTXT "ERROR: THIS SCRIPT MUST BE RUN AS ROOT!"
  YELLOWTXT "------> USE SUPER-USER PRIVILEGES."
  exit 1
  else
  GREENTXT "PASS: ROOT!"
fi

# do we have CentOS 6?
if grep "CentOS.* 7\." /etc/redhat-release  > /dev/null 2>&1; then
  GREENTXT "PASS: CENTOS RELEASE 7"
  else
  echo
  REDTXT "ERROR: UNABLE TO DETERMINE DISTRIBUTION TYPE."
  YELLOWTXT "------> THIS CONFIGURATION FOR CENTOS 7"
  echo
  exit 1
fi

# check if x64.
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
  GREENTXT "PASS: YOUR ARCHITECTURE IS 64-BIT"
  else
  echo
  REDTXT "ERROR: YOUR ARCHITECTURE IS 32-BIT?"
  YELLOWTXT "------> CONFIGURATION FOR 64-BIT ONLY."
  echo
  exit 1
fi

# network is up?
host1=74.125.24.106
host2=208.80.154.225
RESULT=$(((ping -w3 -c2 ${host1} || ping -w3 -c2 ${host2}) > /dev/null 2>&1) && echo "up" || (echo "down" && exit 1))
if [[ ${RESULT} == up ]]; then
  GREENTXT "PASS: NETWORK IS UP. GREAT, LETS START!"
  else
  REDTXT "ERROR: NETWORK IS DOWN?"
  YELLOWTXT "------> PLEASE CHECK YOUR NETWORK SETTINGS."
  echo
  echo
  exit 1
fi

# dumb check for php package
# which php > /dev/null 2>&1
# if [ "$?" = 0 ]
#  then
  # we need php > 5.4.0
#  PHPVER=$(php -v | head -1 | awk {'print $2'})
#  if echo ${PHPVER} 5.4.0 | awk '{exit !( $1 > $2)}'; then
#    GREENTXT "PASS: YOUR PHP IS ${WHITE}${BOLD}${PHPVER}"
#    else
#    REDTXT "ERROR: YOUR PHP VERSION IS NOT > 5.4"
#    YELLOWTXT "------> CONFIGURATION FOR PHP > 5.4 ONLY."
#    echo
#    exit 1
#  fi
#  else
#  REDTXT "ERROR: PHP PACKAGE IS NOT INSTALLED"
#  echo
#  exit
# fi
echo
echo
###################################################################################
#                                     CHECKS END                                  #
###################################################################################
echo
if grep -q "yes" /root/adovms/.terms >/dev/null 2>&1 ; then
echo "...... loading menu"
sleep 1
      else
        YELLOWTXT "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
            echo
        YELLOWTXT "BY INSTALLING THIS SOFTWARE AND BY USING ANY AND ALL SOFTWARE"
        YELLOWTXT "YOU ACKNOWLEDGE AND AGREE:"
            echo
        YELLOWTXT "THIS SOFTWARE AND ALL SOFTWARE PROVIDED IS PROVIDED AS IS"
        YELLOWTXT "UNSUPPORTED AND WE ARE NOT RESPONSIBLE FOR ANY DAMAGE"
            echo
        YELLOWTXT "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
            echo
            echo
	echo -n "---> Do you agree to these terms?  [y/n][y]:"
 	read terms_agree
        if [ "$terms_agree" == "y" ];then
          echo
            mkdir -p /root/adovms
            echo "yes" > /root/adovms/.terms
            else
            echo "Exiting"
           exit 1
          echo
        fi
fi
###################################################################################
#                                  HEADER MENU START                              #
###################################################################################

showMenu () {
printf "\033c"
        echo
        echo
        echo -e "${DGREYBG}${BOLD}  Virtual Mail Server Configuration v.${ADOVMS_VER}  ${RESET}"
        echo -e "\t\t${BLUE}${BOLD}:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::  ${RESET}"
        echo
        echo -e "\t\t${WHITE}${BOLD}-> For packages installation enter     :  ${YELLOW} packages  ${RESET}"
        echo -e "\t\t${WHITE}${BOLD}-> Download and install vimbadmin      :  ${YELLOW} vimbadmin  ${RESET}"
        echo -e "\t\t${WHITE}${BOLD}-> Download and install roundcube      :  ${YELLOW} roundcube  ${RESET}"
        echo -e "\t\t${WHITE}${BOLD}-> Setup and configure everything      :  ${YELLOW} config  ${RESET}"
        echo
        echo -e "\t\t${BLUE}${BOLD}:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::  ${RESET}"
        echo
        echo -e "\t\t${WHITE}${BOLD}-> To quit enter                       :  ${RED} exit  ${RESET}"
        echo
        echo
}
while [ 1 ]
do
        showMenu
        read CHOICE
        case "${CHOICE}" in
"packages")
echo
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
BLUEBG " NOW INSTALLING POSTFIX, DOVECOT, CLAMAV, MILTER, GIT, SUBVERSION, OPENDKIM "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo
echo
echo -n "---> Start mail packages installation? [y/n][n]:"
read mail_install
if [ "${mail_install}" == "y" ];then
    echo
    GREENTXT "Running mail packages installation"
    echo
    rpm -qa | grep -qw epel-release || yum -q -y install ${REPO_EPEL}
    yum --enablerepo=epel-testing -y install ${EXTRA_PACKAGES} ${MAIL_PACKAGES}
    echo
    GREENTXT "Get the latest postfix"
    echo
    rpm -e --nodeps postfix
    rpm -ihv ${POSTFIX}
    echo
    rpm  --quiet -q postfix
    if [ $? = 0 ]
      then
        echo
        GREENTXT "INSTALLED"
        else
        REDTXT "ERROR"
        exit
    fi
        echo
	systemctl enable dovecot
	alternatives --set mta /usr/sbin/sendmail.postfix
        else
        YELLOWTXT "Mail packages installation skipped. Next step"
fi
echo
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
BLUEBG " FINISHED PACKAGES INSTALLATION "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo
echo
pause '------> Press [Enter] key to show menu'
printf "\033c"
;;
"vimbadmin")
echo
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
BLUEBG " NOW DOWNLOADING ViMbAdmin "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo
echo -n "---> Download and configure ViMbAdmin 3? [y/n][n]:"
read vmb_down
if [ "${vmb_down}" == "y" ];then
     read -e -p "---> Edit your installation folder full path: " -i "/var/www/html/vmb" VMB_PATH
        echo
        echo "  ViMbAdmin will be installed into:" 
		GREENTXT ${VMB_PATH}
		echo
		pause '------> Press [Enter] key to continue'
		echo
		mkdir -p ${VMB_PATH} && cd $_
		echo
		###################################################
		git config --global url."https://".insteadOf git://
		###################################################
                git clone git://github.com/opensolutions/ViMbAdmin.git .
		echo
		echo "  Installing Third Party Libraries"
		echo
                cd ${VMB_PATH}
		echo "  Get composer"
		curl -sS https://getcomposer.org/installer | php
		mv composer.phar composer
		echo
                ./composer install
		cp ${VMB_PATH}/public/.htaccess.dist ${VMB_PATH}/public/.htaccess
echo
cat > /root/adovms/.adovms_index <<END
mail	${VMB_PATH}
END
fi
echo
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
BLUEBG " FINISHED ViMbAdmin INSTALLATION "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo
echo
pause '------> Press [Enter] key to show menu'
printf "\033c"
;;
"roundcube")
echo
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
BLUEBG " NOW DOWNLOADING ROUNDCUBE "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo
echo -n "---> Download and configure ROUNDCUBE 1.1.x? [y/n][n]:"
read rcb_down
if [ "${rcb_down}" == "y" ];then
     read -e -p "---> Edit your installation folder full path: " -i "/var/www/html/rcb" RCB_PATH
        echo
        echo "  ROUNDCUBE will be installed into:" 
		GREENTXT ${RCB_PATH}
		echo
		pause '------> Press [Enter] key to continue'
		echo
		mkdir -p ${RCB_PATH}
                cd ${RCB_PATH}
		echo
		wget -qO - http://downloads.sourceforge.net/project/roundcubemail/roundcubemail/1.1.1/roundcubemail-1.1.1.tar.gz | tar -xz --strip 1
		echo
		ls -l ${RCB_PATH}
		echo
		GREENTXT "INSTALLED"
	echo	
	echo	
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
BLUEBG " FINISHED ROUNDCUBE INSTALLATION "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  else
        YELLOWTXT "ROUNDCUBE installation skipped. Next step"
fi
echo
echo
pause '------> Press [Enter] key to show menu'
printf "\033c"
;;
"config")
echo
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
BLUEBG " NOW CONFIGURING POSTFIX, DOVECOT, OPENDKIM, ViMbAdmin AND ROUNDCUBE "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo
printf "\033c"
echo
WHITETXT "Creating virtual mail User and Group"
groupadd -g 5000 vmail
useradd -g vmail -u 5000 vmail -d /home/vmail -m -s /sbin/nologin
echo
WHITETXT "Creating ViMbAdmin MySQL DATABASE and USER"
echo
echo -n "---> Generate ViMbAdmin strong password? [y/n][n]:"
read vmb_pass_gen
if [ "${vmb_pass_gen}" == "y" ];then
   echo
     VMB_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
     WHITETXT "ViMbAdmin database password: ${RED}${VMB_PASSGEN}"
     YELLOWTXT "!REMEMBER IT AND KEEP IT SAFE!"
fi
echo
echo
read -p "---> Enter MySQL ROOT password : " MYSQL_ROOT_PASS
read -p "---> Enter ViMbAdmin database host : " VMB_DB_HOST
read -p "---> Enter ViMbAdmin database name : " VMB_DB_NAME
read -p "---> Enter ViMbAdmin database user : " VMB_DB_USER_NAME
echo
mysql -u root -p${MYSQL_ROOT_PASS} <<EOMYSQL
CREATE USER '${VMB_DB_USER_NAME}'@'${VMB_DB_HOST}' IDENTIFIED BY '${VMB_PASSGEN}';
CREATE DATABASE ${VMB_DB_NAME};
GRANT ALL PRIVILEGES ON ${VMB_DB_NAME}.* TO '${VMB_DB_USER_NAME}'@'${VMB_DB_HOST}' WITH GRANT OPTION;
FLUSH PRIVILEGES;
exit
EOMYSQL
echo
echo
echo -n "---> SETUP ROUNDCUBE MySQL DATABASE AND USER? [y/n][n]:"
read rcb_sdb
if [ "${rcb_sdb}" == "y" ];then
echo
WHITETXT "CREATING ROUNDCUBE MySQL DATABASE AND USER"
echo
echo -n "---> Generate ROUNDCUBE strong password? [y/n][n]:"
read rcb_pass_gen
if [ "${rcb_pass_gen}" == "y" ];then
   echo
     RCB_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
     WHITETXT "ROUNDCUBE database password: ${RED}${RCB_PASSGEN}"
     YELLOWTXT "!REMEMBER IT AND KEEP IT SAFE!"
fi
echo
echo
read -p "---> Enter MySQL ROOT password : " MYSQL_ROOT_PASS
read -p "---> Enter ROUNDCUBE database host : " RCB_DB_HOST
read -p "---> Enter ROUNDCUBE database name : " RCB_DB_NAME
read -p "---> Enter ROUNDCUBE database user : " RCB_DB_USER_NAME
echo
mysql -u root -p${MYSQL_ROOT_PASS} <<EOMYSQL
CREATE USER '${RCB_DB_USER_NAME}'@'${RCB_DB_HOST}' IDENTIFIED BY '${RCB_PASSGEN}';
CREATE DATABASE ${RCB_DB_NAME} /*!40101 CHARACTER SET utf8 COLLATE utf8_general_ci */;
GRANT ALL PRIVILEGES ON ${RCB_DB_NAME}.* TO '${RCB_DB_USER_NAME}'@'${RCB_DB_HOST}' WITH GRANT OPTION;
FLUSH PRIVILEGES;
exit
EOMYSQL
echo
WHITETXT "Import Roundcube database tables..."
mysql -u root -p${MYSQL_ROOT_PASS} ${RCB_DB_NAME} < ${RCB_PATH}/SQL/mysql.initial.sql
  else
  YELLOWTXT "ROUNDCUBE installation skipped. Next step"
fi
echo
WHITETXT "============================================================================="
echo
echo -n "---> Load preconfigured postfix dovecot configs? [y/n][n]:"
read load_configs
if [ "${load_configs}" == "y" ];then
echo
REDTXT "YOU HAVE TO CHECK THEM AFTER ANYWAY"
echo
mkdir -p /etc/postfix/mysql
mkdir -p /etc/postfix/config
WHITETXT "Writing Postfix/ViMbAdmin mysql connection files"
cat > /etc/postfix/mysql/virtual-alias-maps.cf <<END
user = ${VMB_DB_USER_NAME}
password = ${VMB_PASSGEN}
hosts = ${VMB_DB_HOST}
dbname = ${VMB_DB_NAME}
query = SELECT goto FROM alias WHERE address = '%s' AND active = '1'
END
cat > /etc/postfix/mysql/virtual-mailbox-domains.cf <<END
user = ${VMB_DB_USER_NAME}
password = ${VMB_PASSGEN}
hosts = ${VMB_DB_HOST}
dbname = ${VMB_DB_NAME}
query = SELECT domain FROM domain WHERE domain = '%s' AND backupmx = '0' AND active = '1'
END
cat > /etc/postfix/mysql/virtual-mailbox-maps.cf <<END
user = ${VMB_DB_USER_NAME}
password = ${VMB_PASSGEN}
hosts = ${VMB_DB_HOST}
dbname = ${VMB_DB_NAME}
query = SELECT maildir FROM mailbox WHERE username = '%s' AND active = '1'
END
echo
WHITETXT "Writing Postfix main.cf file"
read -p "---> Enter your domain : " VMB_DOMAIN
read -p "---> Enter your hostname : " VMB_MYHOSTNAME
read -p "---> Enter your admin email : " VMB_ADMIN_MAIL
read -e -p "---> Enter your ssl cert location: " -i "/etc/ssl/domain.crt"  VMB_SSL_CRT
read -e -p "---> Enter your ssl key location: " -i "/etc/ssl/server.key"  VMB_SSL_KEY

wget -qO /etc/postfix/main.cf ${POSTFIX_MAIN_CF}
sed -i "s/VMB_SSL_CRT/${VMB_SSL_CRT}/" /etc/postfix/main.cf
sed -i "s/VMB_SSL_KEY/${VMB_SSL_KEY}/" /etc/postfix/main.cf
sed -i "s/VMB_MYHOSTNAME/${VMB_MYHOSTNAME}/" /etc/postfix/main.cf
sed -i "s/VMB_DOMAIN/${VMB_DOMAIN}/" /etc/postfix/main.cf
sed -i "s/VMB_ADMIN_MAIL/${VMB_ADMIN_MAIL}/" /etc/postfix/main.cf

echo
WHITETXT "Writing Dovecot config file"
wget -qO /etc/dovecot/dovecot.conf ${DOVECOT_CONF}
sed -i "s/VMB_SSL_CRT/${VMB_SSL_CRT}/" /etc/dovecot/dovecot.conf
sed -i "s/VMB_SSL_KEY/${VMB_SSL_KEY}/" /etc/dovecot/dovecot.conf
sed -i "s/VMB_ADMIN_MAIL/${VMB_ADMIN_MAIL}/" /etc/dovecot/dovecot.conf

echo
WHITETXT "Writing Dovecot mysql connection file"
wget -qO /etc/dovecot/dovecot-sql.conf ${DOVECOT_SQL_CONF}
sed -i "s/VMB_DB_HOST/${VMB_DB_HOST}/" /etc/dovecot/dovecot-sql.conf
sed -i "s/VMB_DB_NAME/${VMB_DB_NAME}/" /etc/dovecot/dovecot-sql.conf
sed -i "s/VMB_DB_USER_NAME/${VMB_DB_USER_NAME}/" /etc/dovecot/dovecot-sql.conf
sed -i "s/VMB_PASSGEN/${VMB_PASSGEN}/" /etc/dovecot/dovecot-sql.conf

echo
WHITETXT "Writing Postfix PERMIT/REJECT filters. Please uncomment/edit to your needs"
WHITETXT "at /etc/postfix/config/*"

cat > /etc/postfix/config/black_client <<END
#/^.*\@mail\.ru$/        REJECT        Your e-mail was banned!
END

cat > /etc/postfix/config/black_client_ip <<END
#/123\.45\.67\.89/       REJECT        Your IP was banned!
#/123\.45/               REJECT        Your IP-range was banned!
#/xyz\.ua/               REJECT        Your Domain was banned!
#cc\.zxc\.ua/            REJECT        Your Domain was banned!
END

cat > /etc/postfix/config/block_dsl <<END
#/^dsl.*\..*/i                   553 AUTO_DSL Please use your internet provider SMTP Server.
#/.*\.dsl\..*/i                  553 AUTO_DSL2 Please use your internet provider SMTP Server.
#/[a|x]dsl.*\..*\..*/i           553 AUTO_[A|X]DSL Please use your internet provider SMTP Server.
#/client.*\..*\..*/i             553 AUTO_CLIENT Please use your internet provider SMTP Server.
#/cable.*\..*\..*/i              553 AUTO_CABLE Please use your internet provider SMTP Server.
#/pool\..*/i                     553 AUTO_POOL Please use your internet provider SMTP Server.
#/.*dial(\.|-).*\..*\..*/i       553 AUTO_DIAL Please use your internet provider SMTP Server.
#/ppp.*\..*/i                    553 AUTO_PPP Please use your internet provider SMTP Server.
#/dslam.*\..*\..*/i              553 AUTO_DSLAM Please use your internet provider SMTP Server.
#/dslb.*\..*\..*/i               553 AUTO_DSLB Please use your internet provider SMTP Server.
#/node.*\..*\..*/i               553 AUTO_NODE Please use your internet provider SMTP Server.
END

cat > /etc/postfix/config/helo_checks <<END
#/^\[?10\.\d{1,3}\.\d{1,3}\.\d{1,3}\]?$/ REJECT Address in RFC 1918 private network
#/^\[?192\.\d{1,3}\.\d{1,3}\.\d{1,3}\]?$/ REJECT Address in RFC 1918 private network
#/^\[?172\.\d{1,3}\.\d{1,3}\.\d{1,3}\]?$/ REJECT Address in RFC 1918 private network
#/\d{2,}[-\.]+\d{2,}/ REJECT Invalid hostname (D-D)
#/^(((newm|em|gm|m)ail|yandex|rambler|hotbox|chat|rbc|subscribe|spbnit)\.ru)$/ REJECT Faked hostname (\$1)
#/^(((hotmail|mcim|newm|em)ail|post|hotbox|msn|microsoft|aol|news|compuserve|yahoo|google|earthlink|netscape)\.(com|net))$/ REJECT Faked hostname (\$1)
#/[^[] *[0-9]+((\.|-|_)[0-9]+){3}/ REJECT Invalid hostname (ipable)
END

cat > /etc/postfix/config/mx_access <<END
#127.0.0.1      DUNNO 
#127.0.0.2      550 Domains not registered properly
#0.0.0.0/8      REJECT Domain MX in broadcast network 
#10.0.0.0/8     REJECT Domain MX in RFC 1918 private network 
#127.0.0.0/8    REJECT Domain MX in loopback network 
#169.254.0.0/16 REJECT Domain MX in link local network 
#172.16.0.0/12  REJECT Domain MX in RFC 1918 private network 
#192.0.2.0/24   REJECT Domain MX in TEST-NET network 
#192.168.0.0/16 REJECT Domain MX in RFC 1918 private network 
#224.0.0.0/4    REJECT Domain MX in class D multicast network 
#240.0.0.0/5    REJECT Domain MX in class E reserved network 
#248.0.0.0/5    REJECT Domain MX in reserved network
END

cat > /etc/postfix/config/white_client <<END
#/^.*\@mail\.ru$/        PERMIT
END

cat > /etc/postfix/config/white_client_ip <<END
#/91\.214\.209\.5/        PERMIT
END
echo
echo
WHITETXT "Writing Clamav-milter config"
cat > /etc/mail/clamav-milter.conf <<END
MilterSocket inet:127.0.0.1:7357
MilterSocketGroup clamav
MilterSocketMode 660
FixStaleSocket yes
User clamilt
AllowSupplementaryGroups yes
ReadTimeout 120
Foreground no
PidFile /var/run/clamav-milter/clamav-milter.pid
TemporaryDirectory /var/tmp
ClamdSocket unix:/var/run/clamd.scan/clamd.sock
LocalNet local
LocalNet 127.0.0.1
MaxFileSize 25M
OnClean Accept
OnInfected Reject
OnFail Defer
VirusAction /usr/local/bin/my_infected_message_handler
LogFile /var/log/clamav-milter.log
LogFileMaxSize 20M
LogTime yes
LogSyslog yes
LogFacility LOG_MAIL
LogRotate yes
LogInfected Basic
END
echo
echo
WHITETXT "============================================================================="
echo
WHITETXT "Now we going to configure opendkim - generating signing key and configs"
echo
echo
read -p "---> Enter your domains: domain1.com domain2.net domain3.eu: " DKIM_DOMAINS
echo
echo
for DOMAIN in ${DKIM_DOMAINS}
do
# Generate folders and keys
mkdir -p /etc/opendkim/keys/${DOMAIN}
opendkim-genkey -D /etc/opendkim/keys/${DOMAIN}/ -d ${DOMAIN} -s default
chown -R opendkim:opendkim /etc/opendkim/keys/${DOMAIN}
cd /etc/opendkim/keys/${DOMAIN}
cp default.private default
# Add key rule to Table
echo "default._domainkey.${DOMAIN} ${DOMAIN}:default:/etc/opendkim/keys/${DOMAIN}/default.private" >> /etc/opendkim/KeyTable
echo "*@${DOMAIN} default._domainkey.${DOMAIN}" >> /etc/opendkim/SigningTable
echo
GREENTXT " DNS records for ${YELLOW}${BOLD}${DOMAIN} "
cat /etc/opendkim/keys/${DOMAIN}/default.txt
echo "_adsp._domainkey.${DOMAIN} IN TXT dkim=unknown"
WHITETXT "============================================================================="
done
echo
WHITETXT "Loading main opendkim config"
cat > /etc/opendkim.conf <<END
## BEFORE running OpenDKIM you must:
## - edit your DNS records to publish your public keys
## CONFIGURATION OPTIONS
PidFile /var/run/opendkim/opendkim.pid
AutoRestart     yes
AutoRestartRate 5/1h
Mode    sv
Syslog  yes
SyslogSuccess   yes
LogWhy  yes
UserID  opendkim:opendkim
Socket  inet:8891@localhost
Umask   002
## SIGNING OPTIONS
Canonicalization        relaxed/simple
Selector        default
MinimumKeyBits 1024
KeyTable        /etc/opendkim/KeyTable
SigningTable    refile:/etc/opendkim/SigningTable
END
echo
echo
WHITETXT "============================================================================="
echo
pause '------> Press [Enter] key to continue'
echo
echo
WHITETXT "============================================================================="
WHITETXT "============================================================================="
echo
VMB_PATH=$(cat /root/adovms/.adovms_index | grep mail | awk '{print $2}')
WHITETXT "Now we will try to edit ViMbAdmin v3 application.ini file:"
WHITETXT "$VMB_PATH/application/configs/application.ini"
cd ${VMB_PATH}
cp ${VMB_PATH}/application/configs/application.ini.dist ${VMB_PATH}/application/configs/application.ini
sed -i 's/defaults.domain.transport = "virtual"/defaults.domain.transport = "dovecot"/' ${VMB_PATH}/application/configs/application.ini
sed -i 's/defaults.mailbox.uid = 2000/defaults.mailbox.uid = 5000/' ${VMB_PATH}/application/configs/application.ini
sed -i 's/defaults.mailbox.gid = 2000/defaults.mailbox.gid = 5000/' ${VMB_PATH}/application/configs/application.ini
sed -i 's/server.pop3.enabled = 1/server.pop3.enabled = 0/' ${VMB_PATH}/application/configs/application.ini
sed -i "s/resources.doctrine2.connection.options.dbname   = 'vimbadmin'/resources.doctrine2.connection.options.dbname   = '${VMB_DB_NAME}'/" ${VMB_PATH}/application/configs/application.ini
sed -i "s/resources.doctrine2.connection.options.user     = 'vimbadmin'/resources.doctrine2.connection.options.user     = '${VMB_DB_USER_NAME}'/" ${VMB_PATH}/application/configs/application.ini
sed -i "s/resources.doctrine2.connection.options.password = 'xxx'/resources.doctrine2.connection.options.password = '${VMB_PASSGEN}'/" ${VMB_PATH}/application/configs/application.ini
sed -i "s/resources.doctrine2.connection.options.host     = 'localhost'/resources.doctrine2.connection.options.host     = '${VMB_DB_HOST}'/" ${VMB_PATH}/application/configs/application.ini
sed -i 's,defaults.mailbox.maildir = "maildir:/srv/vmail/%d/%u/mail:LAYOUT=fs",defaults.mailbox.maildir = "maildir:/home/vmail/%d/%u",'  ${VMB_PATH}/application/configs/application.ini
sed -i 's,defaults.mailbox.homedir = "/srv/vmail/%d/%u",defaults.mailbox.homedir = "/home/vmail/%d/%u",' ${VMB_PATH}/application/configs/application.ini
sed -i 's/defaults.mailbox.password_scheme = "md5.salted"/defaults.mailbox.password_scheme = "dovecot:SSHA512"/' ${VMB_PATH}/application/configs/application.ini
sed -i 's/server.email.name = "ViMbAdmin Administrator"/server.email.name = "eMail Administrator"/' ${VMB_PATH}/application/configs/application.ini
sed -i 's/server.email.address = "support@example.com"/server.email.address = "'${VMB_ADMIN_MAIL}'"/' ${VMB_PATH}/application/configs/application.ini
echo
WHITETXT "Creating ViMbAdmin v3 database tables:"
./bin/doctrine2-cli.php orm:schema-tool:create
echo
WHITETXT "Now edit ${VMB_PATH}/application/configs/application.ini and configure all parameters in the [user] section"
WHITETXT "except securitysalt - easier to do that later when you first run web frontend"
WHITETXT "monitor mail log   tail -f /var/log/maillog"
echo
fi
echo
pause '------> Press [Enter] key to show menu'
printf "\033c"
;;
"exit")
REDTXT "------> bye"
echo -e "\a"
exit
;;
###################################################################################
#                               MENU DEFAULT CATCH ALL                            #
###################################################################################
*)
printf "\033c"
;;
esac
done