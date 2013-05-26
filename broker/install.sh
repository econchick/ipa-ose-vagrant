#! /bin/bash

set -e
set -x

echo "Exporting env variables"
export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/config.sh

echo "Configuring /etc/hosts ..."
echo "127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4" > /etc/hosts
echo "::1 	localhost localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/hosts
echo "$BROKER_IP_ADDR    $BROKER_FQDN $BROKER_NAME" >> /etc/hosts

echo "Configuring /etc/resolv.conf"
echo "search $IPA_DOMAIN" > /etc/resolv.conf
echo "nameserver $SERVER_IP_ADDR" >> /etc/resolv.conf
echo "nameserver $BROKER_IP_ADDR" >> /etc/resolv.conf

echo "Disabling updates-testing repo ..."
sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/fedora-updates-testing.repo

echo "Downloading IPA rpms ..."
yum install -y freeipa-client freeipa-admintools

echo "Configuring firewalld ..."
firewall-cmd --permanent --zone=public --add-port  80/tcp
firewall-cmd --permanent --zone=public --add-port 443/tcp
firewall-cmd --permanent --zone=public --add-port 389/tcp
firewall-cmd --permanent --zone=public --add-port 636/tcp
firewall-cmd --permanent --zone=public --add-port  88/tcp
firewall-cmd --permanent --zone=public --add-port 464/tcp
firewall-cmd --permanent --zone=public --add-port  53/tcp
firewall-cmd --permanent --zone=public --add-port  88/udp
firewall-cmd --permanent --zone=public --add-port 464/udp
firewall-cmd --permanent --zone=public --add-port  53/udp
firewall-cmd --permanent --zone=public --add-port 123/udp

firewall-cmd --zone=public --add-port  80/tcp
firewall-cmd --zone=public --add-port 443/tcp
firewall-cmd --zone=public --add-port 389/tcp
firewall-cmd --zone=public --add-port 636/tcp
firewall-cmd --zone=public --add-port  88/tcp
firewall-cmd --zone=public --add-port 464/tcp
firewall-cmd --zone=public --add-port  53/tcp
firewall-cmd --zone=public --add-port  88/udp
firewall-cmd --zone=public --add-port 464/udp
firewall-cmd --zone=public --add-port  53/udp
firewall-cmd --zone=public --add-port 123/udp


echo "Installing IPA client ..."
ipa-client-install --enable-dns-updates --ssh-trust-dns -p admin -w $PASSWORD -U

echo "Testing kinit"
echo $PASSWORD | kinit admin

echo "Enrolling HTTP and DNS services"
ipa service-add HTTP/$BROKER_FQDN
ipa service-add DNS/$BROKER_FQDN

echo "Getting keytab for HTTP and DNS services"
ipa-getkeytab -s $SERVER_FQDN -p HTTP/$BROKER_FQDN -k /etc/http.keytab
ipa-getkeytab -s $SERVER_FQDN -p DNS/$BROKER_FQDN -k /etc/dns.keytab


echo "Installing puppet"
yum install puppet -y

echo "Grabbing and installing puppet modules and manifests"
mkdir /etc/puppet/modules
puppet module install openshift/openshift_origin
puppet apply --verbose /etc/puppet/manifests/configure.pp

echo "Restarting services"

service network restart
service activemq restart
service cgconfig restart
service cgred restart
service openshift-cgroups restart
service httpd restart
service openshift-broker restart
service openshift-console restart
service openshift-gears restart
service openshift-node-web-proxy restart
service mcollective restart

echo "Setting appropriate ownership for keytabs"
chown apache:apache /etc/http.keytab
chown apache:apache /etc/dns.keytab

echo "IPA Client and OpenShift Broker complete. Please try the\
the following commands to ensure correct setup:\
kinit admin\
curl -Ik --negotiate -u : https://$BROKER_FQDN/broker/rest/api/\
nsupdate -g <<EOF\
server $SERVER_IP_ADDR\
update add nsupdate-test.$IPA_DOMAIN 60 CNAME $BROKER_FQDN\
send\
update delete nsupdate-test.$IPA_DOMAIN CNAME\
send\
quit\
EOF"

