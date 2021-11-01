#/bin/bash

#This script is written for checking packages. 
#If the system does not have it, it installs via apt. So this script is only for debian based distrubitions.
#Also installed packages are logged into /var/log/installed-packages.log.

#ADD PACKAGES INTO ARRAY
packagesArray=(
    'wget'
    'curl'
)

for package in "${packagesArray[@]}"
do
   if [ $(dpkg-query -W -f='${Status}' ${package} 2>/dev/null | grep -c "ok installed") -eq 1 ];
   then
       echo "${package} already installed"
   else

       apt -y install "$package" && echo "installed '$package'" >> /var/log/installed-packages.log
   fi
done
