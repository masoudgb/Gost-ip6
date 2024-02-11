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
nohup sysctl -w net.ipv4.ip_local_port_range="1024 65535" > /dev/null 2>&1 &

# Options with green color
echo $'\e[35m'"  ___|              |        _ _|  _ \   /    
 |      _ \    __|  __|        |  |   |  _ \  
 |   | (   | \__ \  |          |  ___/  (   | 
\____|\___/  ____/ \__|      ___|_|    \___/  
                                              "$'\e[0m'

echo -e "\e[36mCreated By Masoud Gb Special Thanks Hamid Router\e[0m"
echo $'\e[35m'"Gost Ip6 Script v1.2"$'\e[0m'

options=($'\e[36m1. \e[0mGost Tunnel By IP4'
         $'\e[36m2. \e[0mGost Tunnel By IP6'
         $'\e[36m3. \e[0mAdd New IP'
         $'\e[36m4. \e[0mChange Gost Version'
         $'\e[36m5. \e[0mInstall BBR'
         $'\e[36m6. \e[0mUninstall'
         $'\e[36m7. \e[0mExit')

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
    read -p $'\e[36mPlease enter the desired ports (separated by commas): \e[0m' ports
elif [ "$port_option" -eq 2 ]; then
    read -p $'\e[36mPlease enter the port range (e.g., 54,65000): \e[0m' port_range

    IFS=',' read -ra port_array <<< "$port_range"

    # Check if the start and end port values are within the valid range
    if [ "${port_array[0]}" -lt 54 -o "${port_array[1]}" -gt 65000 ]; then
        echo $'\e[33mInvalid port range. Please enter a valid range starting from 54 and up to 65000.\e[0m'
        exit
    fi

    ports=$(seq -s, "${port_array[0]}" "${port_array[1]}")
else
    echo $'\e[31mInvalid option. Exiting...\e[0m'
    exit
fi

    read -p $'\e[32mSelect the protocol:\n\e[0m\e[36m1. \e[0mBy Tcp Protocol \n\e[36m2. \e[0mBy Grpc Protocol \e[32m\nYour choice: \e[0m' protocol_option

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
    # Prompt user to choose Gost version
    echo $'\e[32mChoose Gost version:\e[0m'
    echo $'\e[36m1. \e[0mGost version 2.11.5 (official)'
    echo $'\e[36m2. \e[0mGost version 3.0.0 (latest)'

    # Read user input for Gost version
    read -p $'\e[97mYour choice: \e[0m' gost_version_choice

    # Download and install Gost based on user's choice
    if [ "$gost_version_choice" -eq 1 ]; then
        echo $'\e[32mInstalling Gost version 2.11.5, please wait...\e[0m' && \
        wget https://github.com/ginuerzh/gost/releases/download/v2.11.5/gost-linux-amd64-2.11.5.gz && \
        echo $'\e[32mGost downloaded successfully.\e[0m' && \
        gunzip gost-linux-amd64-2.11.5.gz && \
        sudo mv gost-linux-amd64-2.11.5 /usr/local/bin/gost && \
        sudo chmod +x /usr/local/bin/gost && \
        echo $'\e[32mGost installed successfully.\e[0m'
    else
        if [ "$gost_version_choice" -eq 2 ]; then
            echo $'\e[32mInstalling Gost version 3.0.0, please wait...\e[0m' && \
            wget https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20240128/gost_3.0.0-nightly.20240128_linux_amd64.tar.gz && \
            echo $'\e[32mGost downloaded successfully.\e[0m' && \
            tar -xvzf gost_3.0.0-nightly.20240128_linux_amd64.tar.gz -C /usr/local/bin/ && \
            cd /usr/local/bin/ && 
            chmod +x gost && \ 
            echo $'\e[32mGost installed successfully.\e[0m'
        else
            echo $'\e[31mInvalid choice. Exiting...\e[0m'
            exit
        fi
    fi

    # Continue creating the systemd service file
    exec_start_command="ExecStart=/usr/local/bin/gost"

    # Add lines for each port
    IFS=',' read -ra port_array <<< "$ports"
    port_count=${#port_array[@]}

    # Set the maximum number of ports per file
    max_ports_per_file=15000

    # Calculate the number of files needed
    file_count=$(( (port_count + max_ports_per_file - 1) / max_ports_per_file ))

    for ((file_index = 0; file_index < file_count; file_index++)); do
        # Create a new systemd service file
        cat <<EOL | sudo tee "/usr/lib/systemd/system/gost_$file_index.service" > /dev/null
[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
EOL

        # Add lines for each port in the current file
        for ((i = file_index * max_ports_per_file; i < (file_index + 1) * max_ports_per_file && i < port_count; i++)); do
            port="${port_array[i]}"
            exec_start_command+=" -L=$protocol://:$port/[$destination_ip]:$port"
        done

        # Append the ExecStart command to the current file
        echo "$exec_start_command" | sudo tee -a "/usr/lib/systemd/system/gost_$file_index.service" > /dev/null

        # Complete the current systemd service file
        cat <<EOL | sudo tee -a "/usr/lib/systemd/system/gost_$file_index.service" > /dev/null

[Install]
WantedBy=multi-user.target
EOL

        # Reload and restart the systemd service
sleep 1
        sudo systemctl enable "gost_$file_index.service"
sleep 1
        sudo systemctl daemon-reload
sleep 2
        sudo systemctl start "gost_$file_index.service"

        # Update exec_start_command for the next iteration
        exec_start_command="ExecStart=/usr/local/bin/gost"
    done

    echo $'\e[32mGost configuration applied successfully.\e[0m'

# If option 3 is selected
elif [ "$choice" -eq 3 ]; then
    read -p $'\e[97mPlease enter the new destination (Kharej) IP 4 or 6: \e[0m' destination_ip
    read -p $'\e[36mPlease enter the new port (separated by commas): \e[0m' port
    read -p $'\e[32mSelect the protocol:\n\e[0m\e[36m1. \e[0mBy Tcp Protocol \n\e[36m2. \e[0mBy Grpc Protocol \e[32m\nYour choice: \e[0m' protocol_option

    if [ "$protocol_option" -eq 1 ]; then
        protocol="tcp"
    elif [ "$protocol_option" -eq 2 ]; then
        protocol="grpc"
    else
        echo $'\e[31mInvalid protocol option. Exiting...\e[0m'
        exit
    fi

    # Use the default protocol previously entered
    echo $'\e[32mYou chose option\e[0m' $choice
    echo $'\e[97mDestination IP:\e[0m' $destination_ip
    echo $'\e[97mPort(s):\e[0m' $port
    echo $'\e[97mProtocol:\e[0m' $protocol

    # Create the systemd service file
    cat <<EOL | sudo tee "/usr/lib/systemd/system/gost_$destination_ip.service" > /dev/null
[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
EOL

    # Add lines for each port
    IFS=',' read -ra port_array <<< "$port"
    port_count=${#port_array[@]}

    # Set the maximum number of ports per file
    max_ports_per_file=15000

    # Calculate the number of files needed
    file_count=$(( (port_count + max_ports_per_file - 1) / max_ports_per_file ))

    for ((file_index = 0; file_index < file_count; file_index++)); do
        # Add lines for each port in the current file
        exec_start_command="ExecStart=/usr/local/bin/gost"
        for ((i = file_index * max_ports_per_file; i < (file_index + 1) * max_ports_per_file && i < port_count; i++)); do
            port="${port_array[i]}"
            exec_start_command+=" -L=$protocol://:$port/[$destination_ip]:$port"
        done

        # Append the ExecStart command to the current file
        echo "$exec_start_command" | sudo tee -a "/usr/lib/systemd/system/gost_$destination_ip.service" > /dev/null
    done

    # Complete the systemd service file
    cat <<EOL | sudo tee -a "/usr/lib/systemd/system/gost_$destination_ip.service" > /dev/null

[Install]
WantedBy=multi-user.target
EOL

    # Reload and restart the systemd service
  sleep 1
        sudo systemctl enable "gost_$file_index.service"
sleep 1
        sudo systemctl daemon-reload
sleep 2
        sudo systemctl start "gost_$file_index.service"

    echo $'\e[32mGost configuration applied successfully.\e[0m'
    bash "$0"

# If option 4 is selected
elif [ "$choice" -eq 4 ]; then
    echo $'\e[32mChoose Gost version:\e[0m'
    echo $'\e[36m1. \e[0mGost version 2.11.5 (official)'
    echo $'\e[36m2. \e[0mGost version 3.0.0 (latest)'

    # Read user input for Gost version
    read -p $'\e[97mYour choice: \e[0m' gost_version_choice

    # Download and install Gost based on user's choice
    case "$gost_version_choice" in
        1)
            echo $'\e[32mInstalling Gost version 2.11.5, please wait...\e[0m' && \
            wget https://github.com/ginuerzh/gost/releases/download/v2.11.5/gost-linux-amd64-2.11.5.gz && \
            echo $'\e[32mGost downloaded successfully.\e[0m' && \
            gunzip gost-linux-amd64-2.11.5.gz && \
            sudo mv gost-linux-amd64-2.11.5 /usr/local/bin/gost && \
            sudo chmod +x /usr/local/bin/gost && \
            echo $'\e[32mGost installed successfully.\e[0m'
            ;;
        2)
            echo $'\e[32mInstalling Gost version 3.0.0, please wait...\e[0m' && \
            wget https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20240128/gost_3.0.0-nightly.20240128_linux_amd64.tar.gz && \
            echo $'\e[32mGost downloaded successfully.\e[0m' && \
            tar -xvzf gost_3.0.0-nightly.20240128_linux_amd64.tar.gz -C /usr/local/bin/ && \
            cd /usr/local/bin/ && \
            chmod +x gost && \
            echo $'\e[32mGost installed successfully.\e[0m'
            ;;
        *)
            echo $'\e[31mInvalid choice. Exiting...\e[0m'
            exit
            ;;
    esac

# If option 5 is selected
elif [ "$choice" -eq 5 ]; then
    echo $'\e[32mInstalling BBR, please wait...\e[0m' && \
    wget -N --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && \
    chmod +x bbr.sh && \
    bash bbr.sh
    bash "$0"
# If option 6 is selected
elif [ "$choice" -eq 6 ]; then
    # Prompt the user for confirmation
    read -p $'\e[91mWarning\e[33m: This will uninstall Gost and remove all related data. Are you sure you want to continue? (y/n): ' uninstall_confirm

    # Check user confirmation
    if [ "$uninstall_confirm" == "y" ]; then
        # Countdown for uninstallation in a single line
        echo $'\e[32mUninstalling Gost in 3 seconds... \e[0m' && sleep 1 && echo $'\e[32m2... \e[0m' && sleep 1 && echo $'\e[32m1... \e[0m' && sleep 1 && { sudo systemctl daemon-reload && sudo systemctl stop gost_*.service && sudo rm -f /usr/local/bin/gost && sudo rm -f /usr/lib/systemd/system/gost_*.service && sudo rm -f /root/gost* && sudo rm -f /etc/systemd/system/multi-user.target.wants/gost_*.service && echo $'\e[32mGost successfully uninstalled.\e[0m'; }
    else
        echo $'\e[32mUninstallation canceled.\e[0m'
    fi
# If option 7 is selected
elif [ "$choice" -eq 7 ]; then
    echo $'\e[32mYou have exited the script.\e[0m'
    exit
fi
