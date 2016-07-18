#!/usr/bin/bash

PASS=Wlogic123
SCRIPTDIR=$PWD
INSTALLDIR=/app/install

# write server name
FTPSERVER=ftp://eprusarw1297

echo "Installing software"
yum install -y wget
cd /tmp
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-7.noarch.rpm
rpm -ivh epel-release-7-7.noarch.rpm

yum install -y mc htop vim zip unzip nmap git ncftp nginx  binutils elfutils-libelf elfutils-libelf-devel gcc gcc-c++ glibc glibc-common glibc-devel glibc-headers ksh libaio libaio-devel libgcc libstdc++ libstdc++-devel make sysstat unixODBC unixODBC-devel xorg-x11-server-Xorg xorg-x11-utils xorg-x11-xauth xorg-x11-fonts-*

wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key

echo "Set Timezone Moscow"
rm -f /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime

echo "Add groups and users"
for srvuser in `more userlist`
do
	echo $srvuser
	groupadd $srvuser
	if [ $srvuser == 'atg' ]
	then
		useradd -d /home/$srvuser -g $srvuser -m -s /usr/bin/bash $srvuser
	else
		useradd -d /home/$srvuser -g $srvuser -G atg -m -s /usr/bin/bash $srvuser
	fi
	echo $PASS | passwd $srvuser --stdin
done
groupadd -g 501 oinstall
groupadd -g 502 dba
groupadd -g 503 oper

useradd -d /home/oracle -m -u 502 -g oinstall -G dba,oper oracle
echo $PASS | passwd oracle --stdin


echo "Create folders and downloading application"
mkdir /app
mkdir $INSTALLDIR
mkdir /app/source
mkdir /app/tools

chmod 755 silent.xml
chmod 755 need_env

cd $INSTALLDIR
ncftpget $FTPSERVER/apache-ant-1.8.3-bin.tar.gz
ncftpget $FTPSERVER/jdk-6u45-linux-x64.bin
ncftpget $FTPSERVER/jdk-7u79-linux-x64.tar.gz
ncftpget $FTPSERVER/wls1036_generic.jar
ncftpget $FTPSERVER/jenkins-cli.jar
ncftpget $FTPSERVER/ATG10.2_394REL.bin
ncftpget $FTPSERVER/p13390677_112040_Linux-x86-64_1of7.zip
ncftpget $FTPSERVER/p13390677_112040_Linux-x86-64_2of7.zip
ncftpget $FTPSERVER/Coherence/coherence-java-3.7.1.0b27797.zip
ncftpget -R $FTPSERVER/endeca

uzip coherence-java-3.7.1.0b27797.zip

chmod +x $(find $PWD -iname "*.sh" -o -iname "*.bin")

echo "Installing Java and Ant"
$INSTALLDIR/jdk-6u45-linux-x64.bin
mkdir /usr/java/
mv jdk1.6.0_45/ /usr/java
ln -s /usr/java/jdk1.6.0_45/ /usr/java/default
ln -s /usr/java/jdk1.6.0_45/ /usr/java/latest
ln -s /usr/java/jdk1.6.0_45/ /app/default
ln -s /usr/java/jdk1.6.0_45/ /app/latest
ln -s /usr/java/latest/bin/java /usr/bin/java
ln -s /usr/java/latest/bin/javac /usr/bin/javac
tar xzf jdk-7u79-linux-x64.tar.gz
mv jdk1.7.0_79/ /usr/java/
chmod -R 755 /usr/java

chown -R atg:atg $INSTALLDIR
chmod 755 $INSTALLDIR

tar xzf apache-ant-1.8.3-bin.tar.gz
mv apache-ant-1.8.3/ /app/tools/

cat /tmp/need_env >> /etc/profile
source /etc/profile

echo "INSTALLING WEBLOGIC"
echo "export MW_HOME=/app/weblogic" >> /home/weblogic/.bash_profile
echo "export WLS_HOME=$MW_HOME/wlserver_10.3" >> /home/weblogic/.bash_profile
echo "export WL_HOME=$WLS_HOME" >> /home/weblogic/.bash_profile
echo "export JAVA_HOME=/usr/java/jdk1.6.0_45" >> /home/weblogic/.bash_profile
echo "export PATH=$PATH:$JAVA_HOME/bin" >> /home/weblogic/.bash_profile

mkdir /app/weblogic
chown -R weblogic:atg /app/weblogic
chmod -R 775 /app/weblogic

su - weblogic -c "
java -Xmx1024m -jar $INSTALLDIR/wls1036_generic.jar -mode=silent -silent_xml=/tmp/silent.xml -log=/tmp/weblogic_install.log
"
su - weblogic -c "
/app/weblogic/wlserver_10.3/common/bin/unpack.sh -java_home=/usr/java/jdk1.6.0_45 -template=/tmp/newtempl.jar -domain=/app/weblogic/user_projects/domains/mstore -user_name=weblogic -password=$PASS
"

chown -R weblogic:atg /app/weblogic

echo "INSTALLING ATG"
su - atg -c "
/app/install/ATG10.2_394REL.bin -f /tmp/atginstall.properties
"

echo "Installing coherence"
cp -R coherence /app/
cp /app/ATG/ATG10.2/DAS/lib/atg-coherence-classes.jar /app/coherence/lib
chown -R coherence:atg /app/coherence
chmod -R 775 /app/coherence

cat /tmp/limits >> /etc/security/limits.conf

yum install -y jenkins

chown atg:atg /app
chmod 775 /app

echo "READ_AFTER_INSTALL"
