#!/bin/bash


echo -e "
 ▄▀▀▀▀▄    ▄▀▀▄▀▀▀▄  ▄▀▀█▄   ▄▀▀▄ ▀▀▄  ▄▀▀▀▀▄    ▄▀▀▀▀▄   ▄▀▀▀▀▄   
█         █   █   █ ▐ ▄▀ ▀▄ █   ▀▄ ▄▀ █    █    █      █ █         
█    ▀▄▄  ▐  █▀▀█▀    █▄▄▄█ ▐     █   ▐    █    █      █ █    ▀▄▄  
█     █ █  ▄▀    █   ▄▀   █       █       █     ▀▄    ▄▀ █     █ █ 
▐▀▄▄▄▄▀ ▐ █     █   █   ▄▀      ▄▀      ▄▀▄▄▄▄▄▄▀ ▀▀▀▀   ▐▀▄▄▄▄▀ ▐ 
▐         ▐     ▐   ▐   ▐       █       █                ▐         
                                ▐       ▐                          
"
echo "This script is tested with root privileges on Ubuntu 20.04."
echo "This script is not meant to use for production environment. Please use it for testing purposes."

echo "NIC must be eth0. If not please modify http_bind_address in /etc/graylog/server/server.conf after the installation and restart the graylog-server service.."
echo "Please be sure that at least 4G memory is free."
echo " "
echo "Written by Akin Unver."

read -r -p "Please enter GUI Admin Password: " pass
adminpass=$( echo -n $pass | shasum -a 256 | cut -d " " -f1 )


#Update the system
sudo apt-get update && sudo apt-get upgrade
sudo apt-get install apt-transport-https openjdk-8-jre-headless uuid-runtime pwgen

#Install Mongodb
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo systemctl daemon-reload
sudo systemctl enable mongod.service
sudo systemctl restart mongod.service

#Install Elasticsearch
wget -q https://artifacts.elastic.co/GPG-KEY-elasticsearch -O myKey
sudo apt-key add myKey
echo "deb https://artifacts.elastic.co/packages/oss-7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get install elasticsearch-oss
echo "cluster.name: graylog" >> /etc/elasticsearch/elasticsearch.yml
echo "action.auto_create_index: false" >> /etc/elasticsearch/elasticsearch.yml

sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl restart elasticsearch.service
sudo systemctl --type=service --state=active | grep elasticsearch

#Install Graylog with Enterprise Features
wget https://packages.graylog2.org/repo/packages/graylog-4.2-repository_latest.deb
sudo dpkg -i graylog-4.2-repository_latest.deb
sudo apt-get update && sudo apt-get install graylog-server graylog-enterprise-plugins graylog-integrations-plugins graylog-enterprise-integrations-plugins

sed -i 's/root_password_sha2/\#root_password_sha2/' /etc/graylog/server/server.conf
sed -i 's/password_secret/\#password_secret/' /etc/graylog/server/server.conf

secretpass=$( pwgen -N 1 -s 96 )
ipv4=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)

echo "root_password_sha2 = $adminpass" >> /etc/graylog/server/server.conf
echo "password_secret = $secretpass" >> /etc/graylog/server/server.conf
echo "http_bind_address = $ipv4:9000" >> /etc/graylog/server/server.conf

sudo systemctl daemon-reload
sudo systemctl enable graylog-server.service
sudo systemctl start graylog-server.service

echo "Done!"
echo "You can connect Graylog from http://$ipv4:9000 with admin:$pass"
echo "Execution of GUI service takes approximately 2 minutes. So be patient."
