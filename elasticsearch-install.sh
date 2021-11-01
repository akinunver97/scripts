#!/bin/bash

#BANNER
echo -e "
 _____ _           _   _                              _     
|  ___| |         | | (_)                            | |    
| |__ | | __ _ ___| |_ _  ___ ___  ___  __ _ _ __ ___| |__  
|  __|| |/ _` / __| __| |/ __/ __|/ _ \/ _` | '__/ __| '_ \ 
| |___| | (_| \__ \ |_| | (__\__ \  __/ (_| | | | (__| | | |
\____/|_|\__,_|___/\__|_|\___|___/\___|\__,_|_|  \___|_| |_|
"
echo "Automation is an art :)"
echo "Written by Akin Unver."
echo ""

interface=$(ifconfig | head -1 | cut -d ":" -f 1)

ip4=$(/sbin/ip -o -4 addr list $interface | awk '{print $4}' | cut -d/ -f1)
hostname=$(cat /etc/hostname)

#VALIDATION
echo "This script should be executed after configuring ip address and hostname."
echo "Current ip: $ip4"
echo -e "Current hostname: $hostname\n"
read -r -p "Are You Sure? [Y/n] " input

case $input in
    [yY][eE][sS]|[yY]|"")
 echo "Last step.."
 ;;
    [nN][oO]|[nN])
 echo "Quiting"
       exit 1;;
    *)
 echo "Invalid input..."
 exit 1
 ;;
esac



#READ



sleep 0.5
read -p 'Elastic Memory[1-32]: ' esmem


if ! (( $esmem >= 1 && $esmem <= 32 )); then
        echo "Entered wrong member number"; exit 1
fi



echo "Let's go!"
echo "force-confold" >> /etc/dpkg/dpkg.cfg
echo "force-confdef" >> /etc/dpkg/dpkg.cfg
sleep 0.5
DEBIAN_FRONTEND=noninteractive
apt update && apt upgrade --assume-yes
apt install wget net-tools
cd /tmp
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.14.1-amd64.deb
dpkg -i elasticsearch-7.14.1-amd64.deb


sed -i 's/\-Xms1g/\-Xms'"$esmem"'g/1' /etc/elasticsearch/jvm.options
sed -i 's/\-Xmx1g/\-Xmx'"$esmem"'g/1' /etc/elasticsearch/jvm.options

systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service


sed -ie 's/\[Service\]/&\nLimitMEMLOCK=infinity/g' /etc/systemd/system/multi-user.target.wants/elasticsearch.service
sed -ie 's/\[Service\]/&\nTimeoutSec=900/g' /etc/systemd/system/multi-user.target.wants/elasticsearch.service


mkdir -p /maydb/elastic/{data,log}
chown -R elasticsearch:elasticsearch /maydb

rm -rf /etc/elasticsearch/elasticsearch.yml
echo -e "cluster.name: maysoccluster \n
path.data: /maydb/elastic/data \n
path.logs: /maydb/elastic/log \n
network.host: $ip4 \n
node.name: $hostname \n
#discovery.seed_hosts: [$ip4] \n
cluster.initial_master_nodes: ["$ip4"] \n
xpack.security.enabled: true \n
xpack.security.transport.ssl.enabled: true " >> /etc/elasticsearch/elasticsearch.yml

systemctl daemon-reload
systemctl restart elasticsearch.service
systemctl restart elasticsearch.service

echo "Put your passwords and you are done !"
sleep 1
/usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive

echo "Bye!"
