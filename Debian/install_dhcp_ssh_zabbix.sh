#!/bin/bash
#This script install SSH-ZABBIX-DHCP on DEBIAN 7-8-9
#Author : Paulo Sérgio Amaral - 27/09/2017
#Please enter the values of your network in the variables

#Var
INTERFACE='eth0' #your nic ( eth0, eth1...) 
SUBNET=''        
NETMASK=''
IP_RANGE_START=''
IP_RANGE_END=''
GATEWAY=''
DNS=''
BROADCAST=''
#TFTP='' #Use only for ASTERIX VOIP 
ZABBIX_SERVER=''

#Verify running as root:
check_user() {
   USER_ID=$(/usr/bin/id -u)
   return $USER_ID
}

  if [ "$USER_ID" > 0 ]; then
  echo "You must be a root user" 2>&1
  exit 1
  fi

#ssh
install_ssh() {
clear
echo -n "Installing Openssh-server \n"
echo "-----------------------------------------"
SSH=$(which ssh | wc -l)
      if [ $SSH -eq 0 ] ; then
      echo "SSH not installed - Installing OPENSSH now - Please wait \n"
      if [ -x /usr/bin/apt-get ]; then
      apt-get install openssh-server wget
      else
      exit 1
      fi
}

# Zabbix Debian 
install_zabbix_cli(){
clear
echo -n "Installing Zabbix Client \n"
echo "-----------------------------------------"
GET_VERSION=$(dpkg --status tzdata|grep Provides|cut -f2 -d'-')
URL="http://repo.zabbix.com/zabbix/3.2/debian/pool/main/z/zabbix-release/zabbix-release_3.2-1+"
URL_DW=$URL$GET_VERSION
echo "Preparing Download Link \n"
if [ -x /usr/bin/apt-get ]; then
  wget ${URL_DW}_all.deb
  dpkg -i zabbix-release_3.2-1+${GET_VERSION}_all.deb
  apt-get update
  apt-get -y install zabbix-agent 
  sed -i "s/Server=127.0.0.1/Server=$ZABBIX_SERVER/" /etc/zabbix/zabbix_agentd.conf
  sed -i "s/ServerActive=127.0.0.1/ServerActive=$ZABBIX_SERVER/" /etc/zabbix/zabbix_agentd.conf
  HOSTNAME=`hostname` && sed -i "s/Hostname=Zabbix\ server/Hostname=$HOSTNAME/" /etc/zabbix/zabbix_agentd.conf
  /etc/init.d/zabbix-agent restart
else
exit 1
fi
}

#Install ISC DHCP
install_dhcp () { 
clear
echo -n 'Installing ISC-DHCP \n'
echo "-----------------------------------------"
  if [ -x /usr/bin/apt-get ]; then
  apt-get -y install isc-dhcp-server
  mv /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bkp
  touch /etc/dhcp/dhcpd.conf
  echo "ddns-update-style none;" >> /etc/dhcp/dhcpd.conf
  echo "default-lease-time 600;" >> /etc/dhcp/dhcpd.conf
  echo "max-lease-time 7200;" >> /etc/dhcp/dhcpd.conf
  echo "authoritative;" >> /etc/dhcp/dhcpd.conf
  echo "option tftp150 code 150 = ip-address;" >> /etc/dhcp/dhcpd.conf
  echo "subnet $SUBNET netmask $NETMASK {" >> /etc/dhcp/dhcpd.conf
  echo "range $IP_RANGE_START $IP_RANGE_END;" >> /etc/dhcp/dhcpd.conf
  echo "option routers $GATEWAY;" >> /etc/dhcp/dhcpd.conf
  echo "option domain-name-servers $DNS;" >> /etc/dhcp/dhcpd.conf
  echo "option broadcast-address $BROADCAST;" >> /etc/dhcp/dhcpd.conf
  echo "option tftp150  $TFTP;" >> /etc/dhcp/dhcpd.conf
  echo "}" >> /etc/dhcp/dhcpd.conf
  mv /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server.bkp
  touch /etc/default/isc-dhcp-server
  echo "INTERFACES=\"$INTERFACE\"" >> /etc/default/isc-dhcp-server
  /etc/init.d/isc-dhcp-server start
  systemctl status isc-dhcp-server.service
  else
  exit 1
  fi
}

install_ssh
install_zabbix_cli
install_dhcp
