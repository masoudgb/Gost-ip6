#!/bin/bash

# Check if the user has root access
if [ "$EUID" -ne 0 ]; then
  echo $'\e[32mPlease run with root privileges.\e[0m'
  exit
fi

echo $'\e[35m'"  ___|              |        _ _|  _ \   /    
 |      _ \    __|  __|        |  |   |  _ \  
 |   | (   | \__ \  |          |  ___/  (   | 
\____|\___/  ____/ \__|      ___|_|    \___/  
                                              "$'\e[0m'

echo -e "\e[36mCreated By Masoud Gb Special Thanks Hamid Router\e[0m"
echo $'\e[35m'"Gost Ip6 Script v2.1.7"$'\e[0m'

options=($'\e[36m1. \e[0mGost Tunnel By IP4'
         $'\e[36m2. \e[0mGost Tunnel By IP6'
         $'\e[36m3. \e[0mGost Status'
         $'\e[36m4. \e[0mUpdate Script'
         $'\e[36m5. \e[0mAdd New IP'
         $'\e[36m6. \e[0mChange Gost Version'
         $'\e[36m7. \e[0mAuto Restart Gost'
         $'\e[36m8. \e[0mInstall BBR'
         $'\e[36m9. \e[0mUninstall'
         $'\e[36m10. \e[0mExit')

# Print prompt and options with cyan color
printf "\e[32mPlease Choice Your Options:\e[0m\n"
printf "%s\n" "${options[@]}"

# Read user input with white color
read -p $'\e[97mYour choice: \e[0m' choice

# If option 1 or 2 is selected
if [ "$choice" -eq 1 ] || [ "$choice" -eq 2 ]; then
    if [ "$choice" -eq 1 ]; then
        read -p $'\e[97mPlease enter the destination (Kharej) IPv4: \e[0m' destination_ip
    elif [ "$choice" -eq 2 ]; then
        read -p $'\e[97mPlease enter the destination (Kharej) IPv6: \e[0m' destination_ip
    fi

    read -p $'\e[32mPlease choose one of the options below:\n\e[0m\e[36m1. \e[0mEnter "Manually" Ports\n\e[36m2. \e[0mEnter "Range" Ports\e[32m\nYour choice: \e[0m' port_option

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

    read -p $'\e[32mSelect the protocol:\n\e[0m\e[36m1. \e[0mBy "Tcp" Protocol \n\e[36m2. \e[0mBy "Udp" Protocol \n\e[36m3. \e[0mBy "Grpc" Protocol \e[32m\nYour choice: \e[0m' protocol_option

if [ "$protocol_option" -eq 1 ]; then
    protocol="tcp"
elif [ "$protocol_option" -eq 2 ]; then
    protocol="udp"
elif [ "$protocol_option" -eq 3 ]; then
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
    echo $'\e[32mUpdating system packages, please wait...\e[0m'
    sysctl net.ipv4.ip_local_port_range="1024 65535"
# Add the sysctl command to the end of the script
echo "sysctl net.ipv4.ip_local_port_range=\"1024 65535\"" >> /etc/rc.local

# Enable the systemd service to run the sysctl command after reboot
cat <<EOL > /etc/systemd/system/sysctl-custom.service
[Unit]
Description=Custom sysctl settings

[Service]
ExecStart=/sbin/sysctl net.ipv4.ip_local_port_range="1024 65535"

[Install]
WantedBy=multi-user.target
EOL
# Enable the service
systemctl enable sysctl-custom

    apt update && sudo apt install wget nano -y && \
    # Add alias for 'gost' to execute the script
        echo 'alias gost="bash /etc/gost/install.sh"' >> ~/.bashrc
        source ~/.bashrc
        echo $'\e[32mSymbolic link created: /usr/local/bin/gost\e[0m'
    echo $'\e[32mSystem update completed.\e[0m'
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
    echo $'\e[32mInstalling Gost version 3.0.0, please wait...\e[0m'
    wget -O /tmp/gost.tar.gz https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20240128/gost_3.0.0-nightly.20240128_linux_amd64.tar.gz
    tar -xvzf /tmp/gost.tar.gz -C /usr/local/bin/
    chmod +x /usr/local/bin/gost
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
    max_ports_per_file=12000

    # Calculate the number of files needed
    file_count=$(( (port_count + max_ports_per_file - 1) / max_ports_per_file ))

    # Continue creating the systemd service files
    for ((file_index = 0; file_index < file_count; file_index++)); do
        # Create a new systemd service file
        cat <<EOL | sudo tee "/usr/lib/systemd/system/gost_$file_index.service" > /dev/null
[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
Environment="GOST_LOGGER_LEVEL=fatal"
EOL

        # Add lines for each port in the current file
        exec_start_command="ExecStart=/usr/local/bin/gost"
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
        sudo systemctl enable "gost_$file_index.service"
        sudo systemctl start "gost_$file_index.service"
        sudo systemctl daemon-reload
        sudo systemctl restart "gost_$file_index.service"
    done

echo $'\e[32mGost configuration applied successfully.\e[0m'
    
# If option 3 is selected
elif [ "$choice" -eq 3 ]; then
    # Check if Gost is installed
    if command -v gost &>/dev/null; then
        echo $'\e[32mGost is installed. Checking configuration and status...\e[0m'
        
        # Check Gost configuration and status
        systemctl list-unit-files | grep -q "gost_"
        if [ $? -eq 0 ]; then
            echo $'\e[32mGost is configured and active.\e[0m'
            
            # Get and display used IPs and ports
            for service_file in /usr/lib/systemd/system/gost_*.service; do
                # Extract the IP, port, and protocol information using awk
                service_info=$(awk -F'[-=:/\\[\\]]+' '/ExecStart=/ {print $14,$15,$22,$20,$23}' "$service_file")

                # Split the extracted information into an array
                read -a info_array <<< "$service_info"

                # Display IP, port, and protocol information with corrected port range
                echo -e "\e[97mIP:\e[0m ${info_array[0]} \e[97mPort:\e[0m ${info_array[1]},... \e[97mProtocol:\e[0m ${info_array[2]}"

            done
        else
            echo $'\e[33mGost is installed, but not configured or active.\e[0m'
        fi
    else
        echo $'\e[33mGost Tunnel is not installed. \e[0m'
    fi

    read -n 1 -s -r -p $'\e[36m0. \e[0mBack to menu: \e[0m' choice

if [ "$choice" -eq 0 ]; then
    bash "$0"
fi

# If option 4 is selected
elif [ "$choice" -eq 4 ]; then
    read -p $'\e[32mDo you want to update Gost script? (y/n): \e[0m' update_choice

    if [ "$update_choice" == "y" ]; then
        echo $'\e[32mUpdating Gost, please wait...\e[0m'
        # Save install.sh in /etc/gost directory
        sudo mkdir -p /etc/gost
wget -O /etc/gost/install.sh https://github.com/masoudgb/Gost-ip6/raw/main/install.sh
chmod +x /etc/gost/install.sh
        echo $'\e[32mUpdate completed.\e[0m'
    else
        echo $'\e[32mUpdate canceled.\e[0m'
    fi

    bash "$0"
fi

# If option 5 is selected
if [ "$choice" -eq 5 ]; then
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
Environment="GOST_LOGGER_LEVEL=fatal"
EOL

    # Add lines for each port
    IFS=',' read -ra port_array <<< "$port"
    port_count=${#port_array[@]}

    # Set the maximum number of ports per file
    max_ports_per_file=12000

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
    sudo systemctl enable "gost_$destination_ip.service"
    sudo systemctl start "gost_$destination_ip.service"
    sudo systemctl daemon-reload
    sudo systemctl restart "gost_$destination_ip.service"
    
    echo $'\e[32mGost configuration applied successfully.\e[0m'
    bash "$0"
# If option 6 is selected
elif [ "$choice" -eq 6 ]; then
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
            wget -O /tmp/gost.tar.gz https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20240128/gost_3.0.0-nightly.20240128_linux_amd64.tar.gz
    tar -xvzf /tmp/gost.tar.gz -C /usr/local/bin/
    chmod +x /usr/local/bin/gost
            echo $'\e[32mGost installed successfully.\e[0m'
            ;;
        *)
            echo $'\e[31mInvalid choice. Exiting...\e[0m'
   exit
            ;;
    esac
    bash "$0"

# If option 7 is selected
elif [ "$choice" -eq 7 ]; then
    echo $'\e[32mChoose Auto Restart option:\e[0m'
    echo $'\e[36m1. \e[0mEnable Auto Restart'
    echo $'\e[36m2. \e[0mDisable Auto Restart'

    # Read user input for Auto Restart option
    read -p $'\e[97mYour choice: \e[0m' auto_restart_option

    # Process user choice for Auto Restart
    case "$auto_restart_option" in
        1)
            # Logic to enable Auto Restart
            echo $'\e[32mAuto Restart Enabled.\e[0m'
            # Remove any existing scheduled restart using 'at' command
            sudo at -l | awk '{print $1}' | xargs -I {} atrm {}
            # Prompt the user for the restart time in hours
            read -p $'\e[97mEnter the restart time in hours: \e[0m' restart_time_hours

            # Convert hours to minutes
            restart_time_minutes=$((restart_time_hours * 60))

            # Write a script to restart Gost
            echo -e "#!/bin/bash\n\nsudo systemctl daemon-reload\nsudo systemctl restart gost_*.service" | sudo tee /usr/bin/auto_restart_cronjob.sh > /dev/null

            # Give execute permission to the script
            sudo chmod +x /usr/bin/auto_restart_cronjob.sh

            # Remove any existing cron job for Auto Restart
            crontab -l | grep -v '/usr/bin/auto_restart_cronjob.sh' | crontab -

            # Write a new cron job to execute the script at the specified intervals
            (crontab -l ; echo "0 */$restart_time_hours * * * /usr/bin/auto_restart_cronjob.sh") | crontab -

            echo $'\e[32mAuto Restart scheduled successfully.\e[0m'
            ;;
        2)
            # Logic to disable Auto Restart
            echo $'\e[32mAuto Restart Disabled.\e[0m'
            # Remove the script and cron job for Auto Restart
            sudo rm -f /usr/bin/auto_restart_cronjob.sh
            crontab -l | grep -v '/usr/bin/auto_restart_cronjob.sh' | crontab -

            echo $'\e[32mAuto Restart disabled successfully.\e[0m'
            ;;
        *)
            echo $'\e[31mInvalid choice. Exiting...\e[0m'
            exit
            ;;
    esac
 bash "$0"
fi
# If option 8 is selected
if [ "$choice" -eq 8 ]; then
    echo $'\e[32mInstalling BBR, please wait...\e[0m' && \
    wget -N --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && \
    chmod +x bbr.sh && \
    bash bbr.sh
    bash "$0"

# If option 9 is selected
elif [ "$choice" -eq 9 ]; then
    # Prompt the user for confirmation
    read -p $'\e[91mWarning\e[33m: This will uninstall Gost and remove all related data. Are you sure you want to continue? (y/n): ' uninstall_confirm

    # Check user confirmation
    if [ "$uninstall_confirm" == "y" ]; then
        # Countdown for uninstallation in a single line
        echo $'\e[32mUninstalling Gost in 3 seconds... \e[0m' && sleep 1 && echo $'\e[32m2... \e[0m' && sleep 1 && echo $'\e[32m1... \e[0m' && sleep 1 && {
            # Remove the auto_restart_cronjob.sh script
            sudo rm -f /usr/bin/auto_restart_cronjob.sh

            # Remove the cron job for Auto Restart
            crontab -l | grep -v '/usr/bin/auto_restart_cronjob.sh' | crontab -

            # Continue with the rest of the uninstallation process
            sudo systemctl daemon-reload
            sudo systemctl stop gost_*.service
            sudo rm -f /usr/local/bin/gost
            sudo rm -rf /etc/gost
            sudo rm -f /usr/lib/systemd/system/gost_*.service
            sudo rm -f /etc/systemd/system/multi-user.target.wants/gost_*.service
            systemctl stop sysctl-custom
            systemctl disable sysctl-custom
            sudo rm -f /etc/systemd/system/sysctl-custom.service
            sudo rm -f /etc/systemd/system/multi-user.target.wants/sysctl-custom.service
            systemctl daemon-reload
            
            echo $'\e[32mGost successfully uninstalled.\e[0m'
        }
    else
        echo $'\e[32mUninstallation canceled.\e[0m'
    fi
    
# If option 10 is selected
elif [ "$choice" -eq 10 ]; then
    echo $'\e[32mYou have exited the script.\e[0m'
    exit
fi
