#!/bin/bash

# Check if the user has root access
if [ "$EUID" -ne 0 ]; then
  echo $'\e[32mPlease run with root privileges.\e[0m'
  exit
fi

# Update the system
echo $'\e[32mUpdating system packages, please wait...\e[0m'
apt update 
echo $'\e[32mSystem update completed.\e[0m'

# Options with green color
echo $'\e[35m'"✩░▒▓▆▅▃▂▁𝐆𝐨𝐬𝐭 𝐢𝐩𝟔▁▂▃▅▆▓▒░✩"$'\e[0m'

echo -e "\e[36mCreated By Masoud Gb Special Thanks Hamid Router\e[0m"
echo $'\e[35m'"Gost Ip6 Script v0.3"$'\e[0m'

options=($'\e[36m1. \e[0mGost Tunnel By IP4'
         $'\e[36m2. \e[0mGost Tunnel By IP6'
         $'\e[36m3. \e[0mUninstall'
         $'\e[36m4. \e[0mExit')

# Print prompt and options with cyan color
printf "\e[32mPlease Choice Your Options:\e[0m\n"
printf "%s\n" "${options[@]}"

# Read user input with white color
read -p $'\e[97mYour choice: \e[0m' choice

# If option 1 or 2 is selected
if [ "$choice" -eq 1 ] || [ "$choice" -eq 2 ]; then

    if [ "$choice" -eq 1 ]; then
        read -p $'\e[97mPlease enter the destination (Kharej) IP: \e[0m' destination_ip
    elif [ "$choice" -eq 2 ]; then
        read -p $'\e[97mPlease enter the destination (Kharej) IPv6: \e[0m' destination_ip
    fi

    read -p $'\e[32mPlease choose one of the options below:\n\e[0m\e[32m1. \e[0mEnter Manually Ports\n\e[32m2. \e[0mEnter Range Ports\e[32m\nYour choice: \e[0m' port_option

    if [ "$port_option" -eq 1 ]; then
        read -p $'\e[97mPlease enter the desired ports (separated by commas): \e[0m' ports
    elif [ "$port_option" -eq 2 ]; then
        read -p $'\e[97mPlease enter the port range (e.g., 1,65535): \e[0m' port_range
        IFS=',' read -ra port_array <<< "$port_range"
        ports=$(IFS=,; echo "${port_array[*]}")
    else
        echo $'\e[31mInvalid option. Exiting...\e[0m'
        exit
    fi

    read -p $'\e[32mSelect the protocol:\n\e[0m\e[32m1. \e[0mBy Tcp Protocol \n\e[32m2. \e[0mBy Grpc Protocol \e[32m\nYour choice: \e[0m' protocol_option

    if [ "$protocol_option" -eq 1 ]; then
        protocol="tcp"
    elif [ "$protocol_option" -eq 2 ]; then
        protocol="grpc"
    else
        echo $'\e[31mInvalid protocol option. Exiting...\e[0m'
        exit
    fi

    echo $'\e[32mYou chose option\e[0m' $choice
    echo $'\e[97mDestination IP:\e[0m' $destination_ip
    echo $'\e[97mPorts:\e[0m' $ports
    echo $'\e[97mProtocol:\e[0m' $protocol

    # Commands to install and configure Gost
    sudo apt install wget nano -y && \
echo $'\e[32mInstalling Gost version 2.11.5, please wait...\e[0m' && \
wget https://github.com/ginuerzh/gost/releases/download/v2.11.5/gost-linux-amd64-2.11.5.gz && \
echo $'\e[32mGost downloaded successfully.\e[0m' && \
gunzip gost-linux-amd64-2.11.5.gz && \
sudo mv gost-linux-amd64-2.11.5 /usr/local/bin/gost && \
sudo chmod +x /usr/local/bin/gost && \
echo $'\e[32mGost installed successfully.\e[0m'

    # Create systemd service file without displaying content
    cat <<EOL | sudo tee /usr/lib/systemd/system/gost.service > /dev/null
[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
EOL

    # Variable to store the ExecStart command
    exec_start_command="ExecStart=/usr/local/bin/gost"

    # Add lines for each port
    IFS=',' read -ra port_array <<< "$ports"
    for port in "${port_array[@]}"; do
        exec_start_command+=" -L=$protocol://:$port/[$destination_ip]:$port"
    done

    # Add the loop for adding additional IPs
    while true; do
        read -p $'\e[36mDo you want to add another destination IP? (y/n): \e[0m' add_another_ip
        if [ "$add_another_ip" == "n" ]; then
            break
        elif [ "$add_another_ip" == "y" ]; then
            read -p $'\e[97mPlease enter the new destination (Kharej) IP: \e[0m' new_destination_ip

            # Use the same protocol as the first choice by default
            new_protocol=$protocol

            read -p $'\e[32mPlease choose one of the options below:\n\e[0m\e[32m1. \e[0mEnter Manually Ports\n\e[32m2. \e[0mEnter Range Ports\e[32m\nYour choice: \e[0m' new_port_option

            if [ "$new_port_option" -eq 1 ]; then
                read -p $'\e[97mPlease enter the desired ports (separated by commas): \e[0m' new_ports
            elif [ "$new_port_option" -eq 2 ]; then
                read -p $'\e[97mPlease enter the port range (e.g., 1,65535): \e[0m' new_port_range
                IFS=',' read -ra new_port_array <<< "$new_port_range"
                new_ports=$(IFS=,; echo "${new_port_array[*]}")
            else
                echo $'\e[31mInvalid option. Exiting...\e[0m'
                exit
            fi

            echo $'\e[97mNew Destination IP:\e[0m' $new_destination_ip
            echo $'\e[97mNew Ports:\e[0m' $new_ports
            echo $'\e[97mNew Protocol:\e[0m' $new_protocol

            # Add lines for each port of the new destination IPs
            IFS=',' read -ra new_port_array <<< "$new_ports"
            for new_port in "${new_port_array[@]}"; do
                exec_start_command+=" -L=$new_protocol://:$new_port/[$new_destination_ip]:$new_port"
            done
        else
            echo $'\e[31mInvalid option. Exiting...\e[0m'
            exit
        fi
    done

    # Continue creating the systemd service file
    echo "$exec_start_command" | sudo tee -a /usr/lib/systemd/system/gost.service > /dev/null

    cat <<EOL | sudo tee -a /usr/lib/systemd/system/gost.service > /dev/null

[Install]
WantedBy=multi-user.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl enable gost.service
    sudo systemctl restart gost.service
    echo $'\e[32mGost configuration applied successfully.\e[0m'

# If option 3 is selected
elif [ "$choice" -eq 3 ]; then
    # Countdown for uninstallation in a single line
    echo $'\e[32mUninstalling Gost in 3 seconds... \e[0m' && sleep 1 && echo $'\e[32m2... \e[0m' && sleep 1 && echo $'\e[32m1... \e[0m' && sleep 1 && { sudo rm -f /usr/local/bin/gost && sudo rm -f /usr/lib/systemd/system/gost.service && echo $'\e[32mGost successfully uninstalled.\e[0m'; }

# If option 4 is selected
elif [ "$choice" -eq 4 ]; then
    echo $'\e[32mYou have exited the script.\e[0m'
    exit
fi
