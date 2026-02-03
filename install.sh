#!/bin/bash

# Check if the user has root access
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[32mPlease run with root privileges.\e[0m"
  exit
fi

show_header() {
    echo -e "\e[35m"
    echo "  ___|              |        _ _|  _ \\   /    "
    echo " |      _ \\    __|  __|        |  |   |  _ \\  "
    echo " |   | (   | \\__ \\  |          |  ___/  (   | "
    echo "\\____|\\___/  ____/ \\__|      ___|_|    \\___/  "
    echo "                                              "
    echo -e "\e[0m"
    echo -e "\e[36mCreated By Masoud Gb Special Thanks Hamid Router\e[0m"
    echo -e "\e[35mGost Ip6 Script v2.4.0\e[0m"
    echo ""
}

get_gost3_versions() {
    echo -e "\e[32mFetching available Gost 3 versions...\e[0m"
    
    versions_json=$(curl -s "https://api.github.com/repos/go-gost/gost/releases?per_page=10")
    
    if [ -z "$versions_json" ] || [ "$versions_json" == "[]" ]; then
        echo -e "\e[31mError: Could not fetch versions from GitHub.\e[0m"
        return 1
    fi
    
    versions=()
    i=1
    while IFS= read -r version; do
        if [ -n "$version" ]; then
            versions[$i]="$version"
            echo -e "\e[36m$i. \e[0mGost $version"
            ((i++))
        fi
    done < <(echo "$versions_json" | grep -oP '"tag_name": "\K([^"]+)' | head -10)
    
    echo ""
    read -p "$(echo -e '\e[97mSelect version (1-10, or 0 for latest stable): \e[0m')" version_choice
    
    if [[ "$version_choice" =~ ^[0-9]+$ ]] && [ "$version_choice" -ge 0 ] && [ "$version_choice" -le 10 ]; then
        if [ "$version_choice" -eq 0 ]; then
            selected_version=$(echo "$versions_json" | grep -oP '"tag_name": "\K([^"]+)' | head -1)
            echo -e "\e[32mSelected: Latest stable version\e[0m"
        else
            selected_version="${versions[$version_choice]}"
            echo -e "\e[32mSelected:\e[0m Gost $selected_version"
        fi
        
        download_url=$(echo "$versions_json" | grep -B2 "$selected_version" | grep -oP '"browser_download_url": "\K(.*?linux.*?\.tar\.gz)(?=")' | head -1)
        
        if [ -z "$download_url" ]; then
            download_url="https://github.com/go-gost/gost/releases/download/${selected_version}/gost_linux_amd64.tar.gz"
        fi
        
        echo "$selected_version" > /tmp/gost_selected_version
        echo "$download_url" > /tmp/gost_download_url
        
        return 0
    else
        echo -e "\e[31mInvalid selection.\e[0m"
        return 1
    fi
}

install_gost2() {
    echo -e "\e[32mInstalling Gost version 2.11.5, please wait...\e[0m"
    wget -q https://github.com/ginuerzh/gost/releases/download/v2.11.5/gost-linux-amd64-2.11.5.gz
    if [ $? -eq 0 ]; then
        gunzip gost-linux-amd64-2.11.5.gz
        mv gost-linux-amd64-2.11.5 /usr/local/bin/gost
        chmod +x /usr/local/bin/gost
        echo -e "\e[32mGost 2.11.5 installed successfully.\e[0m"
        return 0
    else
        echo -e "\e[31mDownload failed. Please check your connection.\e[0m"
        return 1
    fi
}

install_gost3() {
    echo -e "\e[32mInstalling selected Gost 3 version, please wait...\e[0m"
    
    if [ ! -f /tmp/gost_download_url ] || [ ! -f /tmp/gost_selected_version ]; then
        echo -e "\e[31mError: Version information not found.\e[0m"
        get_gost3_versions
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi
    
    download_url=$(cat /tmp/gost_download_url)
    selected_version=$(cat /tmp/gost_selected_version)
    
    echo -e "\e[32mDownloading:\e[0m Gost $selected_version"
    echo -e "\e[32mFrom URL:\e[0m $download_url"
    
    wget -q -O /tmp/gost.tar.gz "$download_url"
    
    if [ $? -ne 0 ] || [ ! -s /tmp/gost.tar.gz ]; then
        echo -e "\e[33mTrying alternative download pattern...\e[0m"
        
        alt_urls=(
            "https://github.com/go-gost/gost/releases/download/${selected_version}/gost-linux-amd64.tar.gz"
            "https://github.com/go-gost/gost/releases/download/${selected_version}/gost_${selected_version}_linux_amd64.tar.gz"
            "https://github.com/go-gost/gost/releases/latest/download/gost_linux_amd64.tar.gz"
        )
        
        for alt_url in "${alt_urls[@]}"; do
            echo -e "\e[33mTrying:\e[0m $alt_url"
            wget -q -O /tmp/gost.tar.gz "$alt_url"
            if [ $? -eq 0 ] && [ -s /tmp/gost.tar.gz ]; then
                echo -e "\e[32mDownload successful with alternative URL.\e[0m"
                break
            fi
        done
    fi
    
    if [ ! -s /tmp/gost.tar.gz ]; then
        echo -e "\e[31mError: Could not download Gost. Please check internet connection.\e[0m"
        rm -f /tmp/gost_download_url /tmp/gost_selected_version
        return 1
    fi

    echo -e "\e[32mExtracting archive...\e[0m"
    
    temp_dir=$(mktemp -d)
    tar -xvzf /tmp/gost.tar.gz -C "$temp_dir" 2>/dev/null
    
    gost_binary=$(find "$temp_dir" -type f -name "gost" -o -name "gost-*" | head -1)
    
    if [ -n "$gost_binary" ] && [ -f "$gost_binary" ]; then
        cp "$gost_binary" /usr/local/bin/gost
        chmod +x /usr/local/bin/gost
        echo -e "\e[32mGost $selected_version installed successfully.\e[0m"
    else
        tar -xvzf /tmp/gost.tar.gz -C /usr/local/bin/ --strip-components=1 2>/dev/null || \
        tar -xvzf /tmp/gost.tar.gz -C /usr/local/bin/ 2>/dev/null
        
        if [ -f /usr/local/bin/gost ]; then
            chmod +x /usr/local/bin/gost
            echo -e "\e[32mGost $selected_version installed successfully.\e[0m"
        else
            echo -e "\e[31mError: Could not find or install gost binary.\e[0m"
            rm -rf "$temp_dir"
            rm -f /tmp/gost.tar.gz /tmp/gost_download_url /tmp/gost_selected_version
            return 1
        fi
    fi
    
    rm -rf "$temp_dir"
    rm -f /tmp/gost.tar.gz /tmp/gost_download_url /tmp/gost_selected_version
    
    if command -v gost &>/dev/null; then
        echo -e "\e[32m✓ Gost is ready to use\e[0m"
        return 0
    else
        echo -e "\e[33m⚠ Gost may not be in PATH. Checking /usr/local/bin/...\e[0m"
        ls -la /usr/local/bin/ | grep -i gost
        return 1
    fi
}

install_gost_version() {
    echo -e "\e[32mChoose Gost version:\e[0m"
    echo -e "\e[36m1. \e[0mGost version 2.11.5 (legacy)"
    echo -e "\e[36m2. \e[0mGost version 3.x (select from recent releases)"
    echo ""

    read -p "$(echo -e '\e[97mYour choice (1 or 2): \e[0m')" gost_version_choice

    case "$gost_version_choice" in
        1)
            install_gost2
            return $?
            ;;
        2)
            get_gost3_versions
            if [ $? -eq 0 ]; then
                install_gost3
                return $?
            else
                return 1
            fi
            ;;
        *)
            echo -e "\e[31mInvalid choice. Please enter 1 or 2.\e[0m"
            return 1
            ;;
    esac
}

configure_system() {
    echo -e "\e[32mConfiguring system, please wait...\e[0m"
    
    sysctl net.ipv4.ip_local_port_range="1024 65535" 2>/dev/null
    echo "sysctl net.ipv4.ip_local_port_range=\"1024 65535\"" >> /etc/rc.local 2>/dev/null
    
    cat <<EOL > /etc/systemd/system/sysctl-custom.service
[Unit]
Description=Custom sysctl settings

[Service]
ExecStart=/sbin/sysctl net.ipv4.ip_local_port_range="1024 65535"

[Install]
WantedBy=multi-user.target
EOL

    systemctl enable sysctl-custom >/dev/null 2>&1
    
    apt update >/dev/null 2>&1 && apt install -y wget nano curl jq >/dev/null 2>&1
    
    echo 'alias gost="bash /etc/gost/install.sh"' >> ~/.bashrc
    source ~/.bashrc >/dev/null 2>&1
    
    echo -e "\e[32mSystem configuration completed.\e[0m"
    return 0
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
        safe_ip=$(echo "$destination_ip" | tr '.:' '_')
        service_name="gost_${safe_ip}_$file_index"
        
        cat <<EOL > "/etc/systemd/system/${service_name}.service"
[Unit]
Description=GO Simple Tunnel ${file_index} for ${destination_ip}
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

        echo "$exec_start_command" >> "/etc/systemd/system/${service_name}.service"

        cat <<EOL >> "/etc/systemd/system/${service_name}.service"
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
EOL

        systemctl enable "${service_name}.service" >/dev/null 2>&1
        systemctl start "${service_name}.service" >/dev/null 2>&1
        
        echo -e "\e[32m✓ Service '${service_name}' started successfully\e[0m"
    done

    systemctl daemon-reload
    echo -e "\e[32m✓ All Gost services configured successfully\e[0m"
    return 0
}

setup_tunnel() {
    install_gost_version
    if [ $? -ne 0 ]; then
        echo -e "\e[33mGost installation failed or was cancelled. Returning to menu...\e[0m"
        sleep 2
        return 1
    fi
    
    echo ""
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mSelect tunnel type:\e[0m"
    echo -e "\e[36m1. \e[0mIPv4 Tunnel"
    echo -e "\e[36m2. \e[0mIPv6 Tunnel"
    echo "══════════════════════════════════════════════════"
    
    read -p "$(echo -e '\e[97mYour choice: \e[0m')" tunnel_type

    case $tunnel_type in
        1)
            read -p "$(echo -e '\e[97mPlease enter the destination IPv4: \e[0m')" destination_ip
            ;;
        2)
            read -p "$(echo -e '\e[97mPlease enter the destination IPv6: \e[0m')" destination_ip
            ;;
        *)
            echo -e "\e[31mInvalid choice.\e[0m"
            return 1
            ;;
    esac

    read -p "$(echo -e '\e[97mPlease enter ports (separated by commas, max 12000 per service): \e[0m')" ports

    echo -e "\e[32mSelect the protocol:\e[0m"
    echo -e "\e[36m1. \e[0mTCP"
    echo -e "\e[36m2. \e[0mUDP"
    echo -e "\e[36m3. \e[0mgRPC"
    
    read -p "$(echo -e '\e[97mYour choice: \e[0m')" protocol_choice

    case $protocol_choice in
        1) protocol="tcp" ;;
        2) protocol="udp" ;;
        3) protocol="grpc" ;;
        *) 
            echo -e "\e[31mInvalid protocol.\e[0m"
            return 1
            ;;
    esac

    echo ""
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mSummary:\e[0m"
    echo -e "\e[97mDestination IP:\e[0m $destination_ip"
    echo -e "\e[97mPorts:\e[0m $ports"
    echo -e "\e[97mProtocol:\e[0m $protocol"
    echo "══════════════════════════════════════════════════"
    echo ""
    
    read -p "$(echo -e '\e[97mProceed with configuration? (y/n): \e[0m')" confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "\e[33mConfiguration cancelled.\e[0m"
        return 1
    fi

    configure_system
    create_gost_service "$destination_ip" "$ports" "$protocol"
    
    echo ""
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32m✓ Tunnel setup completed successfully!\e[0m"
    echo -e "\e[36mTo check status, go to: System Status in main menu\e[0m"
    echo "══════════════════════════════════════════════════"
    echo ""
    
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
    return 0
}

show_status() {
    clear
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mSystem Status:\e[0m"
    echo "══════════════════════════════════════════════════"
    
    if command -v gost &>/dev/null; then
        echo -e "\e[32m✓ Gost is installed\e[0m"
        version_output=$(gost -v 2>/dev/null || echo "Unknown version")
        echo -e "\e[97mVersion:\e[0m $version_output"
    else
        echo -e "\e[33m✗ Gost is not installed\e[0m"
    fi
    
    echo ""
    echo -e "\e[32mActive tunnels:\e[0m"
    
    running_count=$(systemctl list-units --type=service --state=running "gost_*" 2>/dev/null | grep -c "gost_")
    
    if [ "$running_count" -gt 0 ]; then
        systemctl list-units --type=service --state=running "gost_*" --no-pager --full
        echo ""
        echo -e "\e[32mTunnel details:\e[0m"
        
        for service_file in /etc/systemd/system/gost_*.service; do
            [ -e "$service_file" ] || continue
            
            service_name=$(basename "$service_file" .service)
            status=$(systemctl is-active "$service_name" 2>/dev/null)
            
            if [ "$status" = "active" ]; then
                exec_line=$(grep "ExecStart=" "$service_file")
                ip=$(echo "$exec_line" | grep -oP '\[.*?\]' | tr -d '[]' | head -1)
                ports=$(echo "$exec_line" | grep -oP ':\K\d+' | tr '\n' ',' | sed 's/,$//')
                protocol=$(echo "$exec_line" | grep -oP '//:\d+/\K\w+' | head -1)
                
                echo -e "\e[97mService:\e[0m $service_name"
                echo -e "\e[97mIP:\e[0m $ip"
                echo -e "\e[97mPorts:\e[0m $ports"
                echo -e "\e[97mProtocol:\e[0m $protocol"
                echo "──────────────────────────────"
            fi
        done
    else
        echo -e "\e[33mNo active Gost tunnels found\e[0m"
    fi
    
    echo ""
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
    echo ""
}

update_script() {
    echo -e "\e[32mUpdating script...\e[0m"
    mkdir -p /etc/gost
    if wget -O /etc/gost/install.sh https://raw.githubusercontent.com/masoudgb/Gost-ip6/main/install.sh; then
        chmod +x /etc/gost/install.sh
        echo -e "\e[32m✓ Update completed successfully\e[0m"
        echo -e "\e[36mRestarting script with new version...\e[0m"
        sleep 2
        exec bash /etc/gost/install.sh
    else
        echo -e "\e[31m✗ Update failed. Please check network connection.\e[0m"
        sleep 2
    fi
}

add_new_ip() {
    clear
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mAdd New Tunnel Configuration\e[0m"
    echo "══════════════════════════════════════════════════"
    
    read -p "$(echo -e '\e[97mPlease enter the new destination IP: \e[0m')" destination_ip
    read -p "$(echo -e '\e[97mPlease enter ports (separated by commas): \e[0m')" ports
    
    echo -e "\e[32mSelect the protocol:\e[0m"
    echo -e "\e[36m1. \e[0mTCP"
    echo -e "\e[36m2. \e[0mgRPC"
    echo -e "\e[36m3. \e[0mUDP"
    
    read -p "$(echo -e '\e[97mYour choice: \e[0m')" protocol_choice

    case $protocol_choice in
        1) protocol="tcp" ;;
        2) protocol="grpc" ;;
        3) protocol="udp" ;;
        *) 
            echo -e "\e[31mInvalid protocol.\e[0m"
            return
            ;;
    esac

    create_gost_service "$destination_ip" "$ports" "$protocol"
    
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
}

auto_restart() {
    clear
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mAuto Restart Configuration\e[0m"
    echo "══════════════════════════════════════════════════"
    
    echo -e "\e[32mAuto Restart options:\e[0m"
    echo -e "\e[36m1. \e[0mEnable"
    echo -e "\e[36m2. \e[0mDisable"
    
    read -p "$(echo -e '\e[97mYour choice: \e[0m')" choice

    case $choice in
        1)
            read -p "$(echo -e '\e[97mEnter restart interval in hours (1-24): \e[0m')" interval
            if ! [[ "$interval" =~ ^[0-9]+$ ]] || [ "$interval" -lt 1 ] || [ "$interval" -gt 24 ]; then
                echo -e "\e[31mInvalid interval. Must be between 1 and 24 hours.\e[0m"
                return
            fi
            
            cat <<EOL > /usr/bin/auto_restart_gost.sh
#!/bin/bash
systemctl daemon-reload
systemctl restart gost_*.service
EOL
            chmod +x /usr/bin/auto_restart_gost.sh
            
            (crontab -l 2>/dev/null | grep -v auto_restart_gost.sh; echo "0 */${interval} * * * /usr/bin/auto_restart_gost.sh") | crontab -
            echo -e "\e[32m✓ Auto restart enabled (every ${interval} hours)\e[0m"
            ;;
        2)
            rm -f /usr/bin/auto_restart_gost.sh 2>/dev/null
            crontab -l 2>/dev/null | grep -v auto_restart_gost.sh | crontab -
            echo -e "\e[32m✓ Auto restart disabled\e[0m"
            ;;
        *)
            echo -e "\e[31mInvalid choice.\e[0m"
            ;;
    esac
    
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
}

auto_clear_cache() {
    clear
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mAuto Clear Cache Configuration\e[0m"
    echo "══════════════════════════════════════════════════"
    
    echo -e "\e[32mAuto Clear Cache options:\e[0m"
    echo -e "\e[36m1. \e[0mEnable"
    echo -e "\e[36m2. \e[0mDisable"
    
    read -p "$(echo -e '\e[97mYour choice: \e[0m')" choice

    case $choice in
        1)
            read -p "$(echo -e '\e[97mEnter interval in days (1-30): \e[0m')" interval
            if ! [[ "$interval" =~ ^[0-9]+$ ]] || [ "$interval" -lt 1 ] || [ "$interval" -gt 30 ]; then
                echo -e "\e[31mInvalid interval. Must be between 1 and 30 days.\e[0m"
                return
            fi
            
            (crontab -l 2>/dev/null | grep -v drop_caches; echo "0 0 */${interval} * * sync && echo 1 > /proc/sys/vm/drop_caches && echo 2 > /proc/sys/vm/drop_caches && echo 3 > /proc/sys/vm/drop_caches") | crontab -
            echo -e "\e[32m✓ Auto clear cache enabled (every ${interval} days)\e[0m"
            ;;
        2)
            crontab -l 2>/dev/null | grep -v drop_caches | crontab -
            echo -e "\e[32m✓ Auto clear cache disabled\e[0m"
            ;;
        *)
            echo -e "\e[31mInvalid choice.\e[0m"
            ;;
    esac
    
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
}

install_bbr() {
    clear
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mInstalling BBR...\e[0m"
    echo "══════════════════════════════════════════════════"
    
    wget -N --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh
    chmod +x bbr.sh
    bash bbr.sh
    
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
}

uninstall() {
    clear
    echo -e "\e[91m╔══════════════════════════════════════════════════════════╗"
    echo -e "\e[91m║                    WARNING: UNINSTALL                    ║"
    echo -e "\e[91m╚══════════════════════════════════════════════════════════╝"
    echo -e "\e[33mThis will completely remove Gost and all tunnel configurations.\e[0m"
    echo -e "\e[33mAll active tunnels will be stopped and removed.\e[0m"
    echo ""
    
    read -p "$(echo -e '\e[97mAre you absolutely sure? (type YES to confirm): \e[0m')" confirm
    
    if [ "$confirm" != "YES" ]; then
        echo -e "\e[32mUninstall cancelled.\e[0m"
        sleep 2
        return
    fi
    
    echo -e "\e[33mStarting uninstall in 5 seconds...\e[0m"
    for i in 5 4 3 2 1; do
        echo -e "\e[33m${i}...\e[0m"
        sleep 1
    done
    
    echo -e "\e[32mStopping all Gost services...\e[0m"
    systemctl daemon-reload
    systemctl stop gost_*.service 2>/dev/null
    systemctl disable gost_*.service 2>/dev/null
    
    echo -e "\e[32mRemoving service files...\e[0m"
    rm -f /etc/systemd/system/gost_*.service
    rm -f /etc/systemd/system/multi-user.target.wants/gost_*.service
    
    echo -e "\e[32mRemoving Gost binary...\e[0m"
    rm -f /usr/local/bin/gost
    
    echo -e "\e[32mCleaning up configuration...\e[0m"
    rm -rf /etc/gost 2>/dev/null
    
    systemctl stop sysctl-custom 2>/dev/null
    systemctl disable sysctl-custom 2>/dev/null
    rm -f /etc/systemd/system/sysctl-custom.service
    systemctl daemon-reload
    
    rm -f /usr/bin/auto_restart_gost.sh 2>/dev/null
    crontab -l 2>/dev/null | grep -v "gost\|drop_caches" | crontab -
    
    echo -e "\e[32mCleaning up temporary files...\e[0m"
    rm -f /tmp/gost_* 2>/dev/null
    
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32m✓ Gost has been completely uninstalled\e[0m"
    echo "══════════════════════════════════════════════════"
    
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
}

config_menu() {
    while true; do
        clear
        echo "══════════════════════════════════════════════════"
        echo -e "\e[32mConfiguration Menu\e[0m"
        echo "══════════════════════════════════════════════════"
        echo -e "\e[36m1. \e[0mAdd New IP"
        echo -e "\e[36m2. \e[0mChange Gost Version"
        echo -e "\e[36m3. \e[0mAuto Restart"
        echo -e "\e[36m4. \e[0mAuto Clear Cache"
        echo -e "\e[36m5. \e[0mBack to Main Menu"
        echo "══════════════════════════════════════════════════"
        
        read -p "$(echo -e '\e[97mYour choice: \e[0m')" choice

        case $choice in
            1) 
                add_new_ip
                ;;
            2) 
                install_gost_version
                if [ $? -eq 0 ]; then
                    echo -e "\e[32m✓ Gost version changed successfully\e[0m"
                fi
                read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
                ;;
            3) 
                auto_restart
                ;;
            4) 
                auto_clear_cache
                ;;
            5)
                return
                ;;
            *)
                echo -e "\e[31mInvalid choice.\e[0m"
                sleep 1
                ;;
        esac
    done
}

tools_menu() {
    while true; do
        clear
        echo "══════════════════════════════════════════════════"
        echo -e "\e[32mTools Menu\e[0m"
        echo "══════════════════════════════════════════════════"
        echo -e "\e[36m1. \e[0mUpdate Script"
        echo -e "\e[36m2. \e[0mInstall BBR"
        echo -e "\e[36m3. \e[0mUninstall"
        echo -e "\e[36m4. \e[0mBack to Main Menu"
        echo "══════════════════════════════════════════════════"
        
        read -p "$(echo -e '\e[97mYour choice: \e[0m')" choice

        case $choice in
            1) 
                update_script
                ;;
            2) 
                install_bbr
                ;;
            3) 
                uninstall
                ;;
            4)
                return
                ;;
            *)
                echo -e "\e[31mInvalid choice.\e[0m"
                sleep 1
                ;;
        esac
    done
}

main_menu() {
    while true; do
        clear
        show_header
        
        echo "══════════════════════════════════════════════════"
        echo -e "\e[32mMain Menu:\e[0m"
        echo -e "\e[36m1. \e[0mSetup Tunnel"
        echo -e "\e[36m2. \e[0mSystem Status"
        echo -e "\e[36m3. \e[0mConfiguration"
        echo -e "\e[36m4. \e[0mTools"
        echo -e "\e[36m5. \e[0mExit"
        echo "══════════════════════════════════════════════════"
        
        read -p "$(echo -e '\e[97mYour choice: \e[0m')" main_choice

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
                echo -e "\e[32mGoodbye!\e[0m"
                exit 0
                ;;
            *)
                echo -e "\e[31mInvalid choice.\e[0m"
                sleep 1
                ;;
        esac
    done
}

main_menu
