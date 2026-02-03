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
    echo -e "\e[35mGost Ip6 Script v3.0.1\e[0m"
    echo ""
}

show_animation() {
    local text="$1"
    echo -ne "\e[32m"
    echo -n "$text "
    for i in {1..3}; do
        echo -n "."
        sleep 0.3
    done
    echo -e "\e[0m"
}

detect_gost_version() {
    if [ -f /usr/local/bin/gost ]; then
        # Try to get version from binary
        local version_output=$(/usr/local/bin/gost -v 2>&1 | head -1)
        
        if [[ "$version_output" == *"3."* ]]; then
            echo "3"
        elif /usr/local/bin/gost -h 2>&1 | grep -q "ginuerzh"; then
            echo "2"
        else
            echo "unknown"
        fi
    else
        echo "none"
    fi
}

install_gost2() {
    echo -e "\e[32mInstalling Gost version 2.11.5...\e[0m"
    
    # Stop services
    systemctl stop gost_*.service 2>/dev/null
    sleep 1
    
    # Download
    show_animation "Downloading"
    wget -q https://github.com/ginuerzh/gost/releases/download/v2.11.5/gost-linux-amd64-2.11.5.gz
    
    if [ $? -eq 0 ]; then
        show_animation "Extracting"
        gunzip gost-linux-amd64-2.11.5.gz
        mv gost-linux-amd64-2.11.5 /usr/local/bin/gost
        chmod +x /usr/local/bin/gost
        
        # Verify
        if /usr/local/bin/gost -h 2>&1 | grep -q "ginuerzh"; then
            echo -e "\e[32m✓ Gost 2.11.5 installed\e[0m"
            return 0
        else
            echo -e "\e[31m✗ Installation failed\e[0m"
            return 1
        fi
    else
        echo -e "\e[31m✗ Download failed\e[0m"
        return 1
    fi
}

install_gost3() {
    echo -e "\e[32mInstalling Gost version 3.2.6...\e[0m"
    
    # Stop services
    systemctl stop gost_*.service 2>/dev/null
    sleep 1
    
    # Backup
    if [ -f /usr/local/bin/gost ]; then
        cp /usr/local/bin/gost /usr/local/bin/gost.backup.$(date +%s)
    fi
    
    # Download
    show_animation "Downloading"
    wget -q -O /tmp/gost.tar.gz \
        https://github.com/go-gost/gost/releases/download/v3.2.6/gost_3.2.6_linux_amd64.tar.gz
    
    if [ $? -ne 0 ]; then
        # Try alternative
        wget -q -O /tmp/gost.tar.gz \
            https://github.com/go-gost/gost/releases/download/v3.2.6/gost-linux-amd64.tar.gz
    fi
    
    if [ ! -s /tmp/gost.tar.gz ]; then
        echo -e "\e[31m✗ Download failed\e[0m"
        return 1
    fi
    
    show_animation "Extracting"
    
    # Extract directly to target
    tar -xzf /tmp/gost.tar.gz -C /usr/local/bin/ --strip-components=1 2>/dev/null
    
    # If extraction failed, try different approach
    if [ ! -f /usr/local/bin/gost ]; then
        tar -xzf /tmp/gost.tar.gz -C /tmp/
        find /tmp -name "gost" -type f -executable | head -1 | xargs -I {} cp {} /usr/local/bin/gost
    fi
    
    # Set permissions
    if [ -f /usr/local/bin/gost ]; then
        chmod +x /usr/local/bin/gost
        
        # Verify
        if /usr/local/bin/gost -v 2>&1 | grep -q "3."; then
            echo -e "\e[32m✓ Gost 3.2.6 installed\e[0m"
            rm -f /tmp/gost.tar.gz
            return 0
        else
            echo -e "\e[31m✗ Version verification failed\e[0m"
            # Restore backup
            if ls /usr/local/bin/gost.backup.* 2>/dev/null | head -1; then
                cp /usr/local/bin/gost.backup.* /usr/local/bin/gost 2>/dev/null
            fi
            return 1
        fi
    else
        echo -e "\e[31m✗ Binary not found in archive\e[0m"
        return 1
    fi
}

install_gost_version() {
    echo -e "\e[32mChoose Gost version:\e[0m"
    echo -e "\e[36m1. \e[0mGost 2.11.5 (stable)"
    echo -e "\e[36m2. \e[0mGost 3.2.6 (latest)"
    echo -e "\e[36m3. \e[0mCancel"
    echo ""
    
    read -p "$(echo -e '\e[97mYour choice: \e[0m')" choice
    
    case $choice in
        1)
            install_gost2
            ;;
        2)
            install_gost3
            ;;
        3)
            return 1
            ;;
        *)
            echo -e "\e[31mInvalid choice\e[0m"
            return 1
            ;;
    esac
}

configure_system() {
    echo -e "\e[32mConfiguring system...\e[0m"
    apt update >/dev/null 2>&1 && apt install -y wget curl tar gzip >/dev/null 2>&1
    
    # Create alias
    if ! grep -q "alias gost=" ~/.bashrc; then
        echo 'alias gost="bash /etc/gost/install.sh"' >> ~/.bashrc
    fi
    
    source ~/.bashrc >/dev/null 2>&1
    echo -e "\e[32m✓ System configured\e[0m"
    return 0
}

create_gost_service() {
    local destination_ip=$1
    local ports=$2
    local protocol=$3
    
    # Detect version
    local version=$(detect_gost_version)
    if [ "$version" = "none" ] || [ "$version" = "unknown" ]; then
        echo -e "\e[31m✗ Gost not installed or version unknown\e[0m"
        return 1
    fi
    
    echo -e "\e[33mUsing Gost version $version\e[0m"
    
    # Process ports
    IFS=',' read -ra port_array <<< "$ports"
    local port_count=${#port_array[@]}
    local max_ports=50
    local file_count=$(( (port_count + max_ports - 1) / max_ports ))
    
    for ((file_index = 0; file_index < file_count; file_index++)); do
        local safe_ip=$(echo "$destination_ip" | tr '.:/' '_')
        local service_name="gost_${safe_ip}_$((file_index + 1))"
        
        # Stop old service
        systemctl stop "$service_name" 2>/dev/null
        systemctl disable "$service_name" 2>/dev/null
        
        # Create service file
        cat > "/etc/systemd/system/${service_name}.service" <<EOL
[Unit]
Description=Gost Tunnel ${service_name}
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=3
User=root
EOL
        
        # Build command based on version
        local exec_start="ExecStart=/usr/local/bin/gost"
        local port_list=""
        
        for ((i = file_index * max_ports; i < (file_index + 1) * max_ports && i < port_count; i++)); do
            local port="${port_array[i]}"
            port=$(echo "$port" | xargs)
            
            if [[ "$port" =~ ^[0-9]+$ ]]; then
                if [ "$version" = "3" ]; then
                    # Gost 3 syntax
                    exec_start+=" -L :$port -F ${protocol}://[$destination_ip]:$port"
                else
                    # Gost 2 syntax
                    exec_start+=" -L=${protocol}://:$port/[$destination_ip]:$port"
                fi
                port_list+="$port,"
            fi
        done
        
        # Remove trailing comma
        port_list=${port_list%,}
        
        if [ -z "$port_list" ]; then
            rm -f "/etc/systemd/system/${service_name}.service"
            continue
        fi
        
        echo "$exec_start" >> "/etc/systemd/system/${service_name}.service"
        
        # Add footer
        cat >> "/etc/systemd/system/${service_name}.service" <<EOL

[Install]
WantedBy=multi-user.target
EOL
        
        # Enable and start
        systemctl daemon-reload
        systemctl enable "$service_name" >/dev/null 2>&1
        systemctl start "$service_name" >/dev/null 2>&1
        
        sleep 2
        if systemctl is-active --quiet "$service_name"; then
            echo -e "\e[32m✓ Service $service_name started (ports: $port_list)\e[0m"
        else
            echo -e "\e[31m✗ Service $service_name failed\e[0m"
            journalctl -u "$service_name" -n 5 --no-pager
        fi
    done
    
    systemctl daemon-reload
    echo -e "\e[32m✓ Services created\e[0m"
    return 0
}

setup_tunnel() {
    # Install or check Gost
    local version=$(detect_gost_version)
    if [ "$version" = "none" ] || [ "$version" = "unknown" ]; then
        echo -e "\e[33mGost not detected. Installing...\e[0m"
        install_gost_version
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi
    
    echo ""
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mTunnel Setup\e[0m"
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
            echo -e "\e[31mInvalid choice\e[0m"
            return 1
            ;;
    esac
    
    read -p "$(echo -e '\e[97mPort(s) (comma separated): \e[0m')" ports
    
    echo -e "\e[32mSelect protocol:\e[0m"
    echo -e "\e[36m1. \e[0mTCP"
    echo -e "\e[36m2. \e[0mUDP"
    echo -e "\e[36m3. \e[0mgRPC"
    
    read -p "$(echo -e '\e[97mYour choice: \e[0m')" protocol_choice
    
    case $protocol_choice in
        1) protocol="tcp" ;;
        2) protocol="udp" ;;
        3) protocol="grpc" ;;
        *) protocol="tcp" ;;
    esac
    
    # Show summary
    echo ""
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mSummary:\e[0m"
    echo -e "\e[97mDestination:\e[0m $destination_ip"
    echo -e "\e[97mPorts:\e[0m $ports"
    echo -e "\e[97mProtocol:\e[0m $protocol"
    echo -e "\e[97mGost Version:\e[0m $(detect_gost_version)"
    echo "══════════════════════════════════════════════════"
    
    read -p "$(echo -e '\e[97mProceed? (y/n): \e[0m')" confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "\e[33mCancelled\e[0m"
        return 1
    fi
    
    configure_system
    create_gost_service "$destination_ip" "$ports" "$protocol"
    
    echo ""
    echo -e "\e[32m✓ Tunnel setup completed\e[0m"
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
    return 0
}

show_status() {
    clear
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mSYSTEM STATUS\e[0m"
    echo "══════════════════════════════════════════════════"
    
    # Gost info
    local version=$(detect_gost_version)
    if [ "$version" = "none" ]; then
        echo -e "\e[31m✗ Gost not installed\e[0m"
    else
        echo -e "\e[32m✓ Gost installed (v$version)\e[0m"
    fi
    
    # Services
    echo ""
    echo -e "\e[32mActive Tunnels:\e[0m"
    echo "──────────────────────────────────────"
    
    local active_count=0
    for service in /etc/systemd/system/gost_*.service; do
        [ -e "$service" ] || continue
        
        local service_name=$(basename "$service" .service)
        local status=$(systemctl is-active "$service_name" 2>/dev/null)
        
        if [ "$status" = "active" ]; then
            ((active_count++))
            
            # Extract info
            local ip=$(echo "$service_name" | sed 's/gost_//' | sed 's/_[0-9]*$//' | tr '_' '.')
            local ports=$(grep -o ":[0-9]\+" "$service" | tr -d ':' | tr '\n' ',' | sed 's/,$//')
            local protocol=$(grep -o "tcp\|udp\|grpc" "$service" | head -1)
            
            echo -e "\e[97mService:\e[0m $service_name"
            echo -e "\e[97mStatus:\e[0m \e[32m$status\e[0m"
            echo -e "\e[97mIP:\e[0m $ip"
            echo -e "\e[97mPorts:\e[0m $ports"
            echo -e "\e[97mProtocol:\e[0m $protocol"
            echo "──────────────────────────────────────"
        fi
    done
    
    if [ $active_count -eq 0 ]; then
        echo -e "\e[33mNo active tunnels\e[0m"
    else
        echo -e "\e[32mTotal active: $active_count\e[0m"
    fi
    
    # Listening ports
    echo ""
    echo -e "\e[32mListening Ports:\e[0m"
    ss -tulpn 2>/dev/null | grep -E ":(8080|8443|443|80|1080)" | head -10
    
    echo ""
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
}

update_script() {
    echo -e "\e[32mUpdating script...\e[0m"
    
    # Backup
    if [ -f /etc/gost/install.sh ]; then
        cp /etc/gost/install.sh /etc/gost/install.sh.backup
    fi
    
    # Download
    if wget -O /etc/gost/install.sh \
        https://raw.githubusercontent.com/masoudgb/Gost-ip6/main/install.sh; then
        chmod +x /etc/gost/install.sh
        echo -e "\e[32m✓ Update completed\e[0m"
        sleep 2
        exec bash /etc/gost/install.sh
    else
        echo -e "\e[31m✗ Update failed\e[0m"
        sleep 2
    fi
}

add_new_ip() {
    clear
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mADD NEW TUNNEL\e[0m"
    echo "══════════════════════════════════════════════════"
    
    read -p "$(echo -e '\e[97mDestination IP: \e[0m')" destination_ip
    read -p "$(echo -e '\e[97mPort(s): \e[0m')" ports
    
    echo -e "\e[32mProtocol:\e[0m"
    echo -e "\e[36m1. \e[0mTCP"
    echo -e "\e[36m2. \e[0mUDP"
    echo -e "\e[36m3. \e[0mgRPC"
    
    read -p "$(echo -e '\e[97mYour choice: \e[0m')" choice
    
    case $choice in
        1) protocol="tcp" ;;
        2) protocol="udp" ;;
        3) protocol="grpc" ;;
        *) protocol="tcp" ;;
    esac
    
    create_gost_service "$destination_ip" "$ports" "$protocol"
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
}

fix_services() {
    clear
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mFIX SERVICES\e[0m"
    echo "══════════════════════════════════════════════════"
    
    echo -e "\e[36m1. \e[0mRestart all services"
    echo -e "\e[36m2. \e[0mStop all services"
    echo -e "\e[36m3. \e[0mCheck service logs"
    echo -e "\e[36m4. \e[0mBack"
    
    read -p "$(echo -e '\e[97mYour choice: \e[0m')" choice
    
    case $choice in
        1)
            systemctl restart gost_*.service
            echo -e "\e[32m✓ Services restarted\e[0m"
            ;;
        2)
            systemctl stop gost_*.service
            echo -e "\e[32m✓ Services stopped\e[0m"
            ;;
        3)
            echo -e "\e[33mRecent logs:\e[0m"
            journalctl -u gost_* --no-pager -n 20 | tail -20
            ;;
        4)
            return
            ;;
    esac
    
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
            read -p "$(echo -e '\e[97mInterval (hours): \e[0m')" interval
            echo "0 */$interval * * * systemctl restart gost_*.service" | crontab -
            echo -e "\e[32m✓ Auto-restart enabled\e[0m"
            ;;
        2)
            crontab -l | grep -v "gost" | crontab -
            echo -e "\e[32m✓ Auto-restart disabled\e[0m"
            ;;
    esac
    
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
}

uninstall() {
    clear
    echo -e "\e[91m╔════════════════════════════════════════════════╗"
    echo -e "\e[91m║               UNINSTALL GOST                  ║"
    echo -e "\e[91m╚════════════════════════════════════════════════╝"
    
    read -p "$(echo -e '\e[97mType UNINSTALL to confirm: \e[0m')" confirm
    
    if [ "$confirm" != "UNINSTALL" ]; then
        echo -e "\e[33mCancelled\e[0m"
        return
    fi
    
    echo -e "\e[33mUninstalling...\e[0m"
    
    # Stop services
    systemctl stop gost_*.service 2>/dev/null
    systemctl disable gost_*.service 2>/dev/null
    
    # Remove files
    rm -f /etc/systemd/system/gost_*.service
    rm -f /usr/local/bin/gost
    rm -rf /etc/gost 2>/dev/null
    
    # Clean cron
    crontab -l | grep -v "gost" | crontab -
    
    echo -e "\e[32m✓ Gost uninstalled\e[0m"
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
        echo -e "\e[36m3. \e[0mFix Services"
        echo -e "\e[36m4. \e[0mAuto Restart"
        echo -e "\e[36m5. \e[0mBack"
        echo "══════════════════════════════════════════════════"
        
        read -p "$(echo -e '\e[97mYour choice: \e[0m')" choice
        
        case $choice in
            1) add_new_ip ;;
            2) 
                install_gost_version
                read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
                ;;
            3) fix_services ;;
            4) auto_restart ;;
            5) return ;;
            *) echo -e "\e[31mInvalid choice\e[0m"; sleep 1 ;;
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
        echo -e "\e[36m2. \e[0mUninstall"
        echo -e "\e[36m3. \e[0mBack"
        echo "══════════════════════════════════════════════════"
        
        read -p "$(echo -e '\e[97mYour choice: \e[0m')" choice
        
        case $choice in
            1) update_script ;;
            2) uninstall ;;
            3) return ;;
            *) echo -e "\e[31mInvalid choice\e[0m"; sleep 1 ;;
        esac
    done
}

main_menu() {
    while true; do
        clear
        show_header
        
        # Show version
        local version=$(detect_gost_version)
        if [ "$version" = "none" ]; then
            echo -e "\e[31m⚠ Gost not installed\e[0m"
        else
            echo -e "\e[32m✓ Gost v$version installed\e[0m"
        fi
        
        echo ""
        echo "══════════════════════════════════════════════════"
        echo -e "\e[32mMAIN MENU\e[0m"
        echo -e "\e[36m1. \e[0mSetup Tunnel"
        echo -e "\e[36m2. \e[0mSystem Status"
        echo -e "\e[36m3. \e[0mConfiguration"
        echo -e "\e[36m4. \e[0mTools"
        echo -e "\e[36m5. \e[0mExit"
        echo "══════════════════════════════════════════════════"
        
        read -p "$(echo -e '\e[97mYour choice: \e[0m')" choice
        
        case $choice in
            1) setup_tunnel ;;
            2) show_status ;;
            3) config_menu ;;
            4) tools_menu ;;
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

# Create directory
mkdir -p /etc/gost

# Start
main_menu
