#!/bin/bash

# Check if the Gost script is already present in the /etc/gost directory
if [ -f "/etc/gost/install.sh" ]; then
    echo $'\e[32mThe Gost script has been previously downloaded. No repeated download.\e[0m'
else

# Download the Gost script from GitHub
temp_dir=$(mktemp -d)
cd "$temp_dir" || exit
wget https://github.com/masoudgb/Gost-ip6/raw/main/install.sh
sudo mkdir -p /etc/gost
sudo mv install.sh /etc/gost/
sudo chmod +x /etc/gost/install.sh
cd /etc/gost || exit
sudo ./install.sh
rm -rf "$temp_dir"
fi
