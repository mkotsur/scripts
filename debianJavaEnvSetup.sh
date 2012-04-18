#!/bin/sh

USERNAME=`hostname`

if [ ! -d "/home/${USERNAME}" ]; then
  useradd ${USERNAME} -s /bin/bash
  echo "${USERNAME}:${USERNAME}" > chpasswd
  mkdir "/home/${USERNAME}"
  chown ${USERNAME}:${USERNAME} /home/${USERNAME}
fi

apt-get purge -y openjdk-6-jre-lib openjdk-6-jre-headless
apt-get -y update && apt-get -y upgrade
apt-get -y install sudo mc vim git-core subversion wget curl screen mysql-server apache2 libapache2-mod-php5 ant php5-mcrypt php5-curl php5-gd sun-java6-jdk tomcat6

echo "Now modify sudoers file (through visudo) so that: %sudo ALL=(ALL) NOPASSWD: ALL"
echo "Press enter to open sudoers file"
read
visudo

sudo usermod -aG sudo ${USERNAME}

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
# dpkg-reconfigure locales

su ${USERNAME}

cd /tmp && wget http://apache.mirror.easycolocate.nl/maven/binaries/apache-maven-3.0.4-bin.tar.gz && tar -xvzf apache-maven-3.0.4-bin.tar.gz && sudo mv apache-maven-3.0.4 /usr/local/lib && sudo ln -s /usr/local/lib/apache-maven-3.0.4/bin/mvn /usr/local/bin/

# add to /etc/bash.bashrc

sudo bash -c "echo export JAVA_HOME=/usr/lib/jvm/java-6-sun > /home/${USERNAME}/.bashrc"
sudo bash -c 'echo "NameVirtualHost *.80" > /etc/apache2/httpd.conf'

sudo chown -R tomcat6:tomcat6 /etc/tomcat6

sudo a2enmod proxy_http
sudo a2enmod rewrite
sudo apache2ctl restart

echo "Now execute as local user: ssh-copy-id -i ~/.ssh/id_dsa.pub ${USERNAME}@${USERNAME}.ams.intranet"