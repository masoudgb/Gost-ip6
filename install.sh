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
    echo -e "\e[35mGost Ip6 Script v2.6.0\e[0m"
    echo ""
}

show_animation() {
    local text="$1"
    echo -ne "\e[32m"
    echo -n "$text "
    
    # Simple animation
    for i in {1..3}; do
        echo -n "."
        sleep 0.5
    done
    
    echo -e "\e[0m"
}

install_gost2() {
    echo -e "\e[32mInstalling Gost version 2.11.5...\e[0m"
    show_animation "Downloading"
    wget -q https://github.com/ginuerzh/gost/releases/download/v2.11.5/gost-linux-amd64-2.11.5.gz
    
    if [ $? -eq 0 ]; then
        show_animation "Extracting"
        gunzip gost-linux-amd64-2.11.5.gz
        mv gost-linux-amd64-2.11.5 /usr/local/bin/gost
        chmod +x /usr/local/bin/gost
        echo -e "\e[32m✓ Gost 2.11.5 installed successfully\e[0m"
        return 0
    else
        echo -e "\e[31m✗ Download failed. Please check your connection.\e[0m"
        return 1
    fi
}

install_gost3() {
    echo -e "\e[32mInstalling Gost version 3.2.6...\e[0m"
    
    # Direct download URL for Gost 3.2.6
    download_url="https://github.com/go-gost/gost/releases/download/v3.2.6/gost_3.2.6_linux_amd64.tar.gz"
    
    show_animation "Downloading"
    wget -q -O /tmp/gost.tar.gz "$download_url"
    
    if [ $? -ne 0 ] || [ ! -s /tmp/gost.tar.gz ]; then
        echo -e "\e[33mTrying alternative download URL...\e[0m"
        download_url="https://github.com/go-gost/gost/releases/download/v3.2.6/gost-linux-amd64.tar.gz"
        wget -q -O /tmp/gost.tar.gz "$download_url"
    fi

    if [ ! -s /tmp/gost.tar.gz ]; then
        echo -e "\e[31m✗ Download failed. Please check internet connection.\e[0m"
        return 1
    fi

    show_animation "Extracting"
    
    # Create temp directory for extraction
    temp_dir=$(mktemp -d)
    tar -xvzf /tmp/gost.tar.gz -C "$temp_dir" 2>/dev/null
    
    # Find the gost binary
    gost_binary=$(find "$temp_dir" -type f \( -name "gost" -o -name "gost-*" \) | head -1)
    
    if [ -n "$gost_binary" ] && [ -f "$gost_binary" ]; then
        cp "$gost_binary" /usr/local/bin/gost
        chmod +x /usr/local/bin/gost
        echo -e "\e[32m✓ Gost 3.2.6 installed successfully\e[0m"
    else
        # Try direct extraction
        tar -xvzf /tmp/gost.tar.gz -C /usr/local/bin/ --strip-components=1 2>/dev/null || \
        tar -xvzf /tmp/gost.tar.gz -C /usr/local/bin/ 2>/dev/null
        
        if [ -f /usr/local/bin/gost ]; then
            chmod +x /usr/local/bin/gost
            echo -e "\e[32m✓ Gost 3.2.6 installed successfully\e[0m"
        else
            echo -e "\e[31m✗ Could not find gost binary in archive\e[0m"
            rm -rf "$temp_dir"
            rm -f /tmp/gost.tar.gz
            return 1
        fi
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    rm -f /tmp/gost.tar.gz
    
    # Verify installation
    if command -v gost &>/dev/null; then
        echo -e "\e[32m✓ Gost is ready to use\e[0m"
        return 0
    else
        echo -e "\e[33m⚠ Checking /usr/local/bin/ for gost binary...\e[0m"
        return 1
    fi
}

install_gost_version() {
    echo -e "\e[32mChoose Gost version:\e[0m"
    echo -e "\e[36m1. \e[0mGost version 2.11.5 (legacy)"
    echo -e "\e[36m2. \e[0mGost version 3.2.6 (latest)"
    echo ""

    read -p "$(echo -e '\e[97mYour choice (1 or 2): \e[0m')" gost_version_choice

    case "$gost_version_choice" in
        1)
            install_gost2
            return $?
            ;;
        2)
            install_gost3
            return $?
            ;;
        *)
            echo -e "\e[31mInvalid choice. Please enter 1 or 2.\e[0m"
            return 1
            ;;
    esac
}

configure_system() {
    echo -e "\e[32mConfiguring system...\e[0m"
    
    # Update and install dependencies only
    show_animation "Updating packages"
    apt update >/dev/null 2>&1 && apt install -y wget nano curl >/dev/null 2>&1
    
    # Create alias
    echo 'alias gost="bash /etc/gost/install.sh"' >> ~/.bashrc
    source ~/.bashrc >/dev/null 2>&1
    
    echo -e "\e[32m✓ System configuration completed\e[0m"
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
        # Create safe service name
        safe_ip=$(echo "$destination_ip" | tr '.:' '_')
        service_name="gost_${safe_ip}_$file_index"
        
        # Create service file
        cat <<EOL > "/etc/systemd/system/${service_name}.service"
[Unit]
Description=Gost Tunnel ${file_index} for ${destination_ip}
After=network.target

[Service]
Type=simple
Environment="GOST_LOGGER_LEVEL=fatal"
EOL

        # Build ExecStart command
        exec_start_command="ExecStart=/usr/local/bin/gost"
        for ((i = file_index * max_ports_per_file; i < (file_index + 1) * max_ports_per_file && i < port_count; i++)); do
            port="${port_array[i]}"
            exec_start_command+=" -L=$protocol://:$port/[$destination_ip]:$port"
        done

        echo "$exec_start_command" >> "/etc/systemd/system/${service_name}.service"

        # Add service footer
        cat <<EOL >> "/etc/systemd/system/${service_name}.service"
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
EOL

        # Enable and start service
        systemctl enable "${service_name}.service" >/dev/null 2>&1
        systemctl start "${service_name}.service" >/dev/null 2>&1
        
        echo -e "\e[32m✓ Service '${service_name}' started\e[0m"
    done

    systemctl daemon-reload
    echo -e "\e[32m✓ All Gost services configured successfully\e[0m"
    return 0
}

setup_tunnel() {
    # First, choose and install Gost version
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
            read -p "$(echo -e '\e[97mDestination IPv4: \e[0m')" destination_ip
            ;;
        2)
            read -p "$(echo -e '\e[97mDestination IPv6: \e[0m')" destination_ip
            ;;
        *)
            echo -e "\e[31mInvalid choice.\e[0m"
            return 1
            ;;
    esac

    read -p "$(echo -e '\e[97mPorts (separated by commas): \e[0m')" ports

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
    
    read -p "$(echo -e '\e[97mProceed? (y/n): \e[0m')" confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "\e[33mCancelled.\e[0m"
        return 1
    fi

    configure_system
    create_gost_service "$destination_ip" "$ports" "$protocol"
    
    echo ""
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32m✓ Tunnel setup completed!\e[0m"
    echo -e "\e[36mCheck status in System Status menu\e[0m"
    echo "══════════════════════════════════════════════════"
    echo ""
    
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
    return 0
}

show_status() {
    clear
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mSYSTEM STATUS\e[0m"
    echo "══════════════════════════════════════════════════"
    
    # Check Gost installation
    if command -v gost &>/dev/null; then
        echo -e "\e[32m✓ Gost Installed\e[0m"
        
        # Try to get version
        version_info=$(gost -v 2>/dev/null)
        if [ -n "$version_info" ]; then
            echo -e "\e[97mVersion:\e[0m $version_info"
        fi
    else
        echo -e "\e[33m✗ Gost Not Installed\e[0m"
    fi
    
    echo ""
    
    # Check active tunnels
    active_services=$(systemctl list-units --type=service --state=active "gost_*" 2>/dev/null | grep "gost_" | wc -l)
    
    if [ "$active_services" -gt 0 ]; then
        echo -e "\e[32mActive Tunnels: $active_services\e[0m"
        echo "──────────────────────────────────────"
        
        # Get list of active gost services
        systemctl list-units --type=service --state=active "gost_*" 2>/dev/null | grep "gost_" | while read -r line; do
            service_name=$(echo "$line" | awk '{print $1}')
            status=$(echo "$line" | awk '{print $3}')
            
            if [ "$status" = "active" ]; then
                # Extract IP from service name
                ip=$(echo "$service_name" | sed 's/gost_//' | sed 's/_0\.service//' | tr '_' '.' | sed 's/_\([0-9]\+\)$//')
                
                # Try to get more info from service file
                service_file="/etc/systemd/system/${service_name}"
                if [ -f "$service_file" ]; then
                    # Get ports
                    ports_line=$(grep -o ":[0-9]\+/" "$service_file" | tr -d ':/' | tr '\n' ',' | sed 's/,$//')
                    
                    # Get protocol
                    protocol=$(grep -o "tcp\|udp\|grpc" "$service_file" | head -1)
                    
                    echo -e "\e[97mService:\e[0m ${service_name%.service}"
                    echo -e "\e[97mIP:\e[0m $ip"
                    if [ -n "$ports_line" ]; then
                        echo -e "\e[97mPorts:\e[0m $ports_line"
                    fi
                    if [ -n "$protocol" ]; then
                        echo -e "\e[97mProtocol:\e[0m $protocol"
                    fi
                    echo "──────────────────────────────────────"
                fi
            fi
        done
    else
        echo -e "\e[33mNo active tunnels found\e[0m"
    fi
    
    echo ""
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
    echo ""
}

update_script() {
    echo -e "\e[32mUpdating script...\e[0m"
    mkdir -p /etc/gost
    show_animation "Downloading"
    
    if wget -O /etc/gost/install.sh https://raw.githubusercontent.com/masoudgb/Gost-ip6/main/install.sh; then
        chmod +x /etc/gost/install.sh
        echo -e "\e[32m✓ Update completed\e[0m"
        echo -e "\e[36mRestarting with new version...\e[0m"
        sleep 2
        exec bash /etc/gost/install.sh
    else
        echo -e "\e[31m✗ Update failed. Check network connection.\e[0m"
        sleep 2
    fi
}

add_new_ip() {
    clear
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mADD NEW TUNNEL\e[0m"
    echo "══════════════════════════════════════════════════"
    
    read -p "$(echo -e '\e[97mDestination IP: \e[0m')" destination_ip
    read -p "$(echo -e '\e[97mPorts (separated by commas): \e[0m')" ports
    
    echo -e "\e[32mSelect protocol:\e[0m"
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
    echo -e "\e[32mAUTO RESTART\e[0m"
    echo "══════════════════════════════════════════════════"
    
    echo -e "\e[36m1. \e[0mEnable"
    echo -e "\e[36m2. \e[0mDisable"
    
    read -p "$(echo -e '\e[97mYour choice: \e[0m')" choice

    case $choice in
        1)
            read -p "$(echo -e '\e[97mInterval in hours (1-24): \e[0m')" interval
            if ! [[ "$interval" =~ ^[0-9]+$ ]] || [ "$interval" -lt 1 ] || [ "$interval" -gt 24 ]; then
                echo -e "\e[31mInvalid interval\e[0m"
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
            echo -e "\e[31mInvalid choice\e[0m"
            ;;
    esac
    
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
}

auto_clear_cache() {
    clear
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mAUTO CLEAR CACHE\e[0m"
    echo "══════════════════════════════════════════════════"
    
    echo -e "\e[36m1. \e[0mEnable"
    echo -e "\e[36m2. \e[0mDisable"
    
    read -p "$(echo -e '\e[97mYour choice: \e[0m')" choice

    case $choice in
        1)
            read -p "$(echo -e '\e[97mInterval in days (1-30): \e[0m')" interval
            if ! [[ "$interval" =~ ^[0-9]+$ ]] || [ "$interval" -lt 1 ] || [ "$interval" -gt 30 ]; then
                echo -e "\e[31mInvalid interval\e[0m"
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
            echo -e "\e[31mInvalid choice\e[0m"
            ;;
    esac
    
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
}

install_bbr() {
    clear
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mINSTALLING BBR\e[0m"
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
    echo -e "\e[33mThis will remove Gost and all tunnel configurations.\e[0m"
    echo ""
    
    read -p "$(echo -e '\e[97mAre you sure? (type YES to confirm): \e[0m')" confirm
    
    if [ "$confirm" != "YES" ]; then
        echo -e "\e[32mCancelled\e[0m"
        sleep 2
        return
    fi
    
    echo -e "\e[33mUninstalling in 3 seconds...\e[0m"
    for i in 3 2 1; do
        echo -e "\e[33m${i}...\e[0m"
        sleep 1
    done
    
    echo -e "\e[32mStopping services...\e[0m"
    systemctl daemon-reload
    systemctl stop gost_*.service 2>/dev/null
    systemctl disable gost_*.service 2>/dev/null
    
    echo -e "\e[32mRemoving files...\e[0m"
    rm -f /etc/systemd/system/gost_*.service
    rm -f /usr/local/bin/gost
    rm -rf /etc/gost 2>/dev/null
    
    rm -f /usr/bin/auto_restart_gost.sh 2>/dev/null
    crontab -l 2>/dev/null | grep -v "gost\|drop_caches" | crontab -
    
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32m✓ Gost uninstalled successfully\e[0m"
    echo "══════════════════════════════════════════════════"
    
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
}

config_menu() {
    while true; do
        clear
        echo "══════════════════════════════════════════════════"
        echo -e "\e[32mCONFIGURATION\e[0m"
        echo "══════════════════════════════════════════════════"
        echo -e "\e[36m1. \e[0mAdd New Tunnel"
        echo -e "\e[36m2. \e[0mChange Gost Version"
        echo -e "\e[36m3. \e[0mAuto Restart"
        echo -e "\e[36m4. \e[0mAuto Clear Cache"
        echo -e "\e[36m5. \e[0mBack"
        echo "══════════════════════════════════════════════════"
        
        read -p "$(echo -e '\e[97mYour choice: \e[0m')" choice

        case $choice in
            1) 
                add_new_ip
                ;;
            2) 
                install_gost_version
                if [ $? -eq 0 ]; then
                    echo -e "\e[32m✓ Version changed\e[0m"
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
                echo -e "\e[31mInvalid choice\e[0m"
                sleep 1
                ;;
        esac
    done
}

tools_menu() {
    while true; do
        clear
        echo "══════════════════════════════════════════════════"
        echo -e "\e[32mTOOLS\e[0m"
        echo "══════════════════════════════════════════════════"
        echo -e "\e[36m1. \e[0mUpdate Script"
        echo -e "\e[36m2. \e[0mInstall BBR"
        echo -e "\e[36m3. \e[0mUninstall"
        echo -e "\e[36m4. \e[0mBack"
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
                echo -e "\e[31mInvalid choice\e[0m"
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
        echo -e "\e[32mMAIN MENU\e[0m"
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
                echo -e "\e[31mInvalid choice\e[0m"
                sleep 1
                ;;
        esac
    done
}

main_menu
