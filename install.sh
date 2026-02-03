#!/bin/bash

# Check if the user has root access
if [ "$EUID" -ne 0 ]; then
  echo $'\e[32mPlease run with root privileges.\e[0m'
  exit
fi

show_header() {
    echo $'\e[35m'"  ___|              |        _ _|  _ \   /    
 |      _ \    __|  __|        |  |   |  _ \  
 |   | (   | \__ \  |          |  ___/  (   | 
\____|\___/  ____/ \__|      ___|_|    \___/  
                                              "$'\e[0m'
    echo -e "\e[36mCreated By Masoud Gb Special Thanks Hamid Router\e[0m"
    echo $'\e[35m'"Gost Ip6 Script v2.3.0"$'\e[0m'
}

install_gost2() {
    echo $'\e[32mInstalling Gost version 2.11.5, please wait...\e[0m' && \
    wget https://github.com/ginuerzh/gost/releases/download/v2.11.5/gost-linux-amd64-2.11.5.gz && \
    echo $'\e[32mGost downloaded successfully.\e[0m' && \
    gunzip gost-linux-amd64-2.11.5.gz && \
    sudo mv gost-linux-amd64-2.11.5 /usr/local/bin/gost && \
    sudo chmod +x /usr/local/bin/gost && \
    echo $'\e[32mGost installed successfully.\e[0m'
}

install_gost3() {
    echo $'\e[32mInstalling the latest stable Gost version 3.x, please wait...\e[0m'
    
    LATEST_URL=$(curl -s https://api.github.com/repos/go-gost/gost/releases/latest | grep -oP '"browser_download_url": "\K(.*?linux-amd64.*?\.tar\.gz)(?=")' | head -n 1)
    
    if [ -z "$LATEST_URL" ]; then
        LATEST_URL="https://github.com/go-gost/gost/releases/latest/download/gost-linux-amd64.tar.gz"
    fi

    echo $'\e[32mDownloading latest stable Gost...\e[0m'
    wget -O /tmp/gost.tar.gz "$LATEST_URL"
    
    if [ ! -f /tmp/gost.tar.gz ]; then
        echo $'\e[31mError: Download failed.\e[0m'
        exit 1
    fi

    if [ ! -s /tmp/gost.tar.gz ]; then
        echo $'\e[31mError: The downloaded file is empty.\e[0m'
        exit 1
    fi

    tar -xvzf /tmp/gost.tar.gz -C /usr/local/bin/ --strip-components=1
    chmod +x /usr/local/bin/gost
    echo $'\e[32mGost installed successfully.\e[0m'
}

install_gost_version() {
    echo $'\e[32mChoose Gost version:\e[0m'
    echo $'\e[36m1. \e[0mGost version 2.11.5 (legacy)'
    echo $'\e[36m2. \e[0mGost version 3.x (latest stable)'

    read -p $'\e[97mYour choice: \e[0m' gost_version_choice

    case "$gost_version_choice" in
        1)
            install_gost2
            ;;
        2)
            install_gost3
            ;;
        *)
            echo $'\e[31mInvalid choice.\e[0m'
            return 1
            ;;
    esac
}

configure_system() {
    echo $'\e[32mConfiguring system, please wait...\e[0m'
    sysctl net.ipv4.ip_local_port_range="1024 65535"
    echo "sysctl net.ipv4.ip_local_port_range=\"1024 65535\"" >> /etc/rc.local

    cat <<EOL > /etc/systemd/system/sysctl-custom.service
[Unit]
Description=Custom sysctl settings

[Service]
ExecStart=/sbin/sysctl net.ipv4.ip_local_port_range="1024 65535"

[Install]
WantedBy=multi-user.target
EOL

    systemctl enable sysctl-custom
    apt update && apt install wget nano -y
    echo 'alias gost="bash /etc/gost/install.sh"' >> ~/.bashrc
    source ~/.bashrc
    echo $'\e[32mSystem configuration completed.\e[0m'
}

create_gost_service() {
    local destination_ip=$1
    local ports=$2
    local protocol=$3
    
    IFS=',' read -ra port_array <<< "$ports"
    port_count=${#port_array[@]}
    max_ports_per_file=12000
    file_count=$(( (port_count + max_ports_per_file - 1) / max_ports_per_file ))

    for ((file_index = 0; file_index < file_count; file_index++)); do
        service_name="gost_${destination_ip//[.:]/_}_$file_index"
        
        cat <<EOL | sudo tee "/usr/lib/systemd/system/${service_name}.service" > /dev/null
[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
Environment="GOST_LOGGER_LEVEL=fatal"
EOL

        exec_start_command="ExecStart=/usr/local/bin/gost"
        for ((i = file_index * max_ports_per_file; i < (file_index + 1) * max_ports_per_file && i < port_count; i++)); do
            port="${port_array[i]}"
            exec_start_command+=" -L=$protocol://:$port/[$destination_ip]:$port"
        done

        echo "$exec_start_command" | sudo tee -a "/usr/lib/systemd/system/${service_name}.service" > /dev/null

        cat <<EOL | sudo tee -a "/usr/lib/systemd/system/${service_name}.service" > /dev/null

[Install]
WantedBy=multi-user.target
EOL

        sudo systemctl enable "${service_name}.service"
        sudo systemctl start "${service_name}.service"
    done

    sudo systemctl daemon-reload
    echo $'\e[32mGost configuration applied successfully.\e[0m'
}

setup_tunnel() {
    echo $'\e[32mSelect tunnel type:\e[0m'
    echo $'\e[36m1. \e[0mIPv4 Tunnel'
    echo $'\e[36m2. \e[0mIPv6 Tunnel'
    
    read -p $'\e[97mYour choice: \e[0m' tunnel_type

    case $tunnel_type in
        1)
            read -p $'\e[97mPlease enter the destination IPv4: \e[0m' destination_ip
            ;;
        2)
            read -p $'\e[97mPlease enter the destination IPv6: \e[0m' destination_ip
            ;;
        *)
            echo $'\e[31mInvalid choice.\e[0m'
            return 1
            ;;
    esac

    read -p $'\e[97mPlease enter ports (separated by commas): \e[0m' ports

    echo $'\e[32mSelect the protocol:\e[0m'
    echo $'\e[36m1. \e[0mTCP'
    echo $'\e[36m2. \e[0mUDP'
    echo $'\e[36m3. \e[0mgRPC'
    
    read -p $'\e[97mYour choice: \e[0m' protocol_choice

    case $protocol_choice in
        1) protocol="tcp" ;;
        2) protocol="udp" ;;
        3) protocol="grpc" ;;
        *) 
            echo $'\e[31mInvalid protocol.\e[0m'
            return 1
            ;;
    esac

    install_gost_version
    if [ $? -eq 0 ]; then
        configure_system
        create_gost_service "$destination_ip" "$ports" "$protocol"
    fi
}

show_status() {
    if command -v gost &>/dev/null; then
        echo $'\e[32mGost is installed.\e[0m'
        
        if systemctl list-unit-files | grep -q "gost_"; then
            echo $'\e[32mActive tunnels:\e[0m'
            for service_file in /usr/lib/systemd/system/gost_*.service; do
                [ -e "$service_file" ] || continue
                exec_line=$(grep "ExecStart=" "$service_file")
                ip=$(echo "$exec_line" | grep -oP '\[.*?\]' | tr -d '[]' | head -1)
                ports=$(echo "$exec_line" | grep -oP ':\K\d+' | head -1)
                protocol=$(echo "$exec_line" | grep -oP '//:\d+/\K\w+' | head -1)
                echo -e "\e[97mIP:\e[0m $ip \e[97mPort:\e[0m $ports \e[97mProtocol:\e[0m $protocol"
            done
        else
            echo $'\e[33mNo active tunnels.\e[0m'
        fi
    else
        echo $'\e[33mGost is not installed.\e[0m'
    fi
    
    read -n 1 -s -r -p $'\e[36mPress any key to continue...\e[0m'
}

update_script() {
    echo $'\e[32mUpdating script...\e[0m'
    sudo mkdir -p /etc/gost
    wget -O /etc/gost/install.sh https://github.com/masoudgb/Gost-ip6/raw/main/install.sh
    chmod +x /etc/gost/install.sh
    echo $'\e[32mUpdate completed. Run the script again.\e[0m'
    exit 0
}

add_new_ip() {
    read -p $'\e[97mPlease enter the new destination IP: \e[0m' destination_ip
    read -p $'\e[97mPlease enter ports (separated by commas): \e[0m' ports
    
    echo $'\e[32mSelect the protocol:\e[0m'
    echo $'\e[36m1. \e[0mTCP'
    echo $'\e[36m2. \e[0mgRPC'
    
    read -p $'\e[97mYour choice: \e[0m' protocol_choice

    case $protocol_choice in
        1) protocol="tcp" ;;
        2) protocol="grpc" ;;
        *) 
            echo $'\e[31mInvalid protocol.\e[0m'
            return
            ;;
    esac

    create_gost_service "$destination_ip" "$ports" "$protocol"
}

auto_restart() {
    echo $'\e[32mAuto Restart options:\e[0m'
    echo $'\e[36m1. \e[0mEnable'
    echo $'\e[36m2. \e[0mDisable'
    
    read -p $'\e[97mYour choice: \e[0m' choice

    case $choice in
        1)
            read -p $'\e[97mEnter restart interval in hours: \e[0m' interval
            cat <<EOL > /usr/bin/auto_restart_gost.sh
#!/bin/bash
systemctl daemon-reload
systemctl restart gost_*.service
EOL
            chmod +x /usr/bin/auto_restart_gost.sh
            (crontab -l 2>/dev/null | grep -v auto_restart_gost.sh; echo "0 */$interval * * * /usr/bin/auto_restart_gost.sh") | crontab -
            echo $'\e[32mAuto restart enabled.\e[0m'
            ;;
        2)
            rm -f /usr/bin/auto_restart_gost.sh
            crontab -l 2>/dev/null | grep -v auto_restart_gost.sh | crontab -
            echo $'\e[32mAuto restart disabled.\e[0m'
            ;;
    esac
}

auto_clear_cache() {
    echo $'\e[32mAuto Clear Cache options:\e[0m'
    echo $'\e[36m1. \e[0mEnable'
    echo $'\e[36m2. \e[0mDisable'
    
    read -p $'\e[97mYour choice: \e[0m' choice

    case $choice in
        1)
            read -p $'\e[97mEnter interval in days: \e[0m' interval
            (crontab -l 2>/dev/null | grep -v drop_caches; echo "0 0 */$interval * * sync && echo 1 > /proc/sys/vm/drop_caches && echo 2 > /proc/sys/vm/drop_caches && echo 3 > /proc/sys/vm/drop_caches") | crontab -
            echo $'\e[32mAuto clear cache enabled.\e[0m'
            ;;
        2)
            crontab -l 2>/dev/null | grep -v drop_caches | crontab -
            echo $'\e[32mAuto clear cache disabled.\e[0m'
            ;;
    esac
}

install_bbr() {
    echo $'\e[32mInstalling BBR...\e[0m'
    wget -N --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh
    chmod +x bbr.sh
    bash bbr.sh
}

uninstall() {
    read -p $'\e[91mWarning\e[33m: This will uninstall Gost. Continue? (y/n): ' confirm
    
    if [ "$confirm" == "y" ]; then
        echo $'\e[32mUninstalling...\e[0m'
        sleep 3
        
        sudo systemctl daemon-reload
        sudo systemctl stop gost_*.service
        sudo rm -f /usr/local/bin/gost
        sudo rm -rf /etc/gost
        sudo rm -f /usr/lib/systemd/system/gost_*.service
        sudo rm -f /etc/systemd/system/multi-user.target.wants/gost_*.service
        
        systemctl stop sysctl-custom
        systemctl disable sysctl-custom
        sudo rm -f /etc/systemd/system/sysctl-custom.service
        systemctl daemon-reload
        
        rm -f /usr/bin/auto_restart_gost.sh
        crontab -l 2>/dev/null | grep -v "gost\|drop_caches" | crontab -
        
        echo $'\e[32mUninstallation completed.\e[0m'
    else
        echo $'\e[32mCancelled.\e[0m'
    fi
}

main_menu() {
    show_header
    
    echo $'\e[32mMain Menu:\e[0m'
    echo $'\e[36m1. \e[0mSetup Tunnel'
    echo $'\e[36m2. \e[0mSystem Status'
    echo $'\e[36m3. \e[0mConfiguration'
    echo $'\e[36m4. \e[0mTools'
    echo $'\e[36m5. \e[0mExit'
    
    read -p $'\e[97mYour choice: \e[0m' main_choice

    case $main_choice in
        1)
            setup_tunnel
            ;;
        2)
            show_status
            ;;
        3)
            config_menu
            ;;
        4)
            tools_menu
            ;;
        5)
            echo $'\e[32mGoodbye!\e[0m'
            exit 0
            ;;
        *)
            echo $'\e[31mInvalid choice.\e[0m'
            ;;
    esac
    
    main_menu
}

config_menu() {
    echo $'\e[32mConfiguration:\e[0m'
    echo $'\e[36m1. \e[0mAdd New IP'
    echo $'\e[36m2. \e[0mChange Gost Version'
    echo $'\e[36m3. \e[0mAuto Restart'
    echo $'\e[36m4. \e[0mAuto Clear Cache'
    echo $'\e[36m5. \e[0mBack'
    
    read -p $'\e[97mYour choice: \e[0m' choice

    case $choice in
        1) add_new_ip ;;
        2) install_gost_version ;;
        3) auto_restart ;;
        4) auto_clear_cache ;;
        5) return ;;
        *) echo $'\e[31mInvalid choice.\e[0m' ;;
    esac
    
    config_menu
}

tools_menu() {
    echo $'\e[32mTools:\e[0m'
    echo $'\e[36m1. \e[0mUpdate Script'
    echo $'\e[36m2. \e[0mInstall BBR'
    echo $'\e[36m3. \e[0mUninstall'
    echo $'\e[36m4. \e[0mBack'
    
    read -p $'\e[97mYour choice: \e[0m' choice

    case $choice in
        1) update_script ;;
        2) install_bbr ;;
        3) uninstall ;;
        4) return ;;
        *) echo $'\e[31mInvalid choice.\e[0m' ;;
    esac
    
    tools_menu
}

main_menu
