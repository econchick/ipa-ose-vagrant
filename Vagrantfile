# -*- mode: ruby -*-
# vi: set ft=ruby :

$SERVER_SCRIPT = <<EOF
export LOG=/var/log/vagrant-ipa-server-setup.log ;\
touch $LOG; \
source /vagrant/server/config.sh | tee -a $LOG;\
sh /vagrant/server/install.sh    | tee -a $LOG;
EOF

$BROKER_SCRIPT = <<EOF
export LOG=/var/log/vagrant-ipa-broker-setup.log ;\
touch $LOG; \
source /vagrant/broker/config.sh | tee -a $LOG;\
sh /vagrant/broker/install.sh    | tee -a $LOG;
EOF

$DEV_SCRIPT = <<EOF
export LOG=/var/log/vagrant-ipa-dev-setup.log ; \
touch $LOG \
source /vagrant/dev/config.sh | tee -a $LOG;\
sh /vagrant/dev/install.sh    | tee -a $LOG;
EOF

Vagrant.configure("2") do |config|
  config.vm.box = "Fedora-18"
  
  config.vm.define :ipaserver do |ipaserver|
    ipaserver.vm.network :forwarded_port, guest: 80, host: 8080
    ipaserver.vm.network :forwarded_port, guest: 443, host: 1443
    ipaserver.vm.network :private_network, ip: "192.168.10.15"
    ipaserver.vm.hostname = "ipaserver.example.com"
    ipaserver.vm.synced_folder "server/", "/vagrant/server"
    ipaserver.vm.provision :shell, :inline => $SERVER_SCRIPT
  end

  config.vm.define :broker do |broker|
    broker.vm.network :forwarded_port, guest: 80, host: 8888
    broker.vm.network :forwarded_port, guest: 443, host: 2443
    broker.vm.network :private_network, ip: "192.168.10.20"
    broker.vm.hostname = "broker.example.com"
    broker.vm.synced_folder "broker/", "/vagrant/broker"
    broker.vm.synced_folder "manifests/", "/etc/puppet/manifests"
    broker.vm.provision :shell, :inline => $BROKER_SCRIPT
  end

  config.vm.define :dev do |dev|
    dev.vm.network :forwarded_port, guest: 80, host: 8998
    dev.vm.network :forwarded_port, guest: 443, host: 3443
    dev.vm.network :private_network, ip: "192.168.10.25"
    dev.vm.hostname = "dev.example.com"
    dev.vm.synced_folder "dev/", "/vagrant/dev"
    dev.vm.provision :shell, :inline => $DEV_SCRIPT
  end
end