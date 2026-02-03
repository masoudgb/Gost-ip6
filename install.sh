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
    echo -e "\e[35mGost Ip6 Script v2.7.0\e[0m"
    echo ""
}

show_animation() {
    local text="$1"
    echo -ne "\e[32m"
    echo -n "$text "
    
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
    
    temp_dir=$(mktemp -d)
    tar -xvzf /tmp/gost.tar.gz -C "$temp_dir" 2>/dev/null
    
    gost_binary=$(find "$temp_dir" -type f \( -name "gost" -o -name "gost-*" \) | head -1)
    
    if [ -n "$gost_binary" ] && [ -f "$gost_binary" ]; then
        cp "$gost_binary" /usr/local/bin/gost
        chmod +x /usr/local/bin/gost
        echo -e "\e[32m✓ Gost 3.2.6 installed successfully\e[0m"
    else
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
    
    rm -rf "$temp_dir"
    rm -f /tmp/gost.tar.gz
    
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
    
    # حذف تنظیمات sysctl که دیگر نیاز نیست
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
    local gost_version=$4
    
    IFS=',' read -ra port_array <<< "$ports"
    port_count=${#port_array[@]}
    max_ports_per_file=12000
    file_count=$(( (port_count + max_ports_per_file - 1) / max_ports_per_file ))

    for ((file_index = 0; file_index < file_count; file_index++)); do
        safe_ip=$(echo "$destination_ip" | tr '.:' '_')
        service_name="gost_${safe_ip}_$file_index"
        
        cat <<EOL > "/etc/systemd/system/${service_name}.service"
[Unit]
Description=Gost Tunnel ${file_index} for ${destination_ip}
After=network.target

[Service]
Type=simple
Environment="GOST_LOGGER_LEVEL=fatal"
EOL

        # 🔥 این بخش اصلاح شده - تفاوت بین Gost 2 و Gost 3
        exec_start_command="ExecStart=/usr/local/bin/gost"
        
        if [ "$gost_version" = "2" ]; then
            # دستور قدیمی Gost 2
            for ((i = file_index * max_ports_per_file; i < (file_index + 1) * max_ports_per_file && i < port_count; i++)); do
                port="${port_array[i]}"
                exec_start_command+=" -L=$protocol://:$port/[$destination_ip]:$port"
            done
        else
            # دستور جدید Gost 3
            for ((i = file_index * max_ports_per_file; i < (file_index + 1) * max_ports_per_file && i < port_count; i++)); do
                port="${port_array[i]}"
                
                if [ "$protocol" = "grpc" ]; then
                    # برای gRPC در Gost 3
                    exec_start_command+=" -L grpc://:$port -F relay+$protocol://$destination_ip:$port"
                else
                    # برای TCP/UDP در Gost 3
                    exec_start_command+=" -L $protocol://:$port -F relay+$protocol://$destination_ip:$port"
                fi
            done
        fi

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
    
    # ذخیره نسخه انتخاب شده
    if command -v gost &>/dev/null; then
        gost_version_output=$(gost -v 2>/dev/null || echo "")
        if [[ "$gost_version_output" == *"3."* ]]; then
            gost_version="3"
        else
            gost_version="2"
        fi
    else
        gost_version="$gost_version_choice" # 1 = gost2, 2 = gost3
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

    echo ""
    echo -e "\e[32mPort options:\e[0m"
    echo -e "\e[36m1. \e[0mEnter single port or multiple ports (comma separated)"
    echo -e "\e[36m2. \e[0mEnter port range (e.g., 1000,2000)"
    echo ""
    
    read -p "$(echo -e '\e[97mYour choice: \e[0m')" port_option

    case $port_option in
        1)
            read -p "$(echo -e '\e[97mPort(s) (comma separated): \e[0m')" ports
            ;;
        2)
            read -p "$(echo -e '\e[97mPort range (start,end): \e[0m')" port_range
            IFS=',' read -ra range_array <<< "$port_range"
            if [ ${#range_array[@]} -eq 2 ]; then
                ports=$(seq -s, "${range_array[0]}" "${range_array[1]}")
            else
                echo -e "\e[31mInvalid port range format.\e[0m"
                return 1
            fi
            ;;
        *)
            echo -e "\e[31mInvalid choice.\e[0m"
            return 1
            ;;
    esac

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
    echo -e "\e[97mGost Version:\e[0m $([ "$gost_version" = "2" ] && echo "2.11.5" || echo "3.2.6")"
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
    create_gost_service "$destination_ip" "$ports" "$protocol" "$gost_version"
    
    echo ""
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32m✓ Tunnel setup completed!\e[0m"
    
    # نمایش دستور اجرا شده برای دیباگ
    if [ "$gost_version" = "2" ]; then
        echo -e "\e[33mCommand format: gost -L=$protocol://:PORT/[$destination_ip]:PORT\e[0m"
    else
        echo -e "\e[33mCommand format: gost -L $protocol://:PORT -F relay+$protocol://$destination_ip:PORT\e[0m"
    fi
    
    echo -e "\e[36mCheck status in System Status menu\e[0m"
    echo "══════════════════════════════════════════════════"
    echo ""
    
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
    return 0
}

# بقیه توابع (show_status, update_script, add_new_ip, auto_restart, auto_clear_cache, install_bbr, uninstall, config_menu, tools_menu, main_menu)
# دقیقاً مانند نسخه قبلی باقی می‌مانند اما با یک تغییر کوچک در add_new_ip

add_new_ip() {
    clear
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mADD NEW TUNNEL\e[0m"
    echo "══════════════════════════════════════════════════"
    
    # تشخیص نسخه Gost نصب شده
    if command -v gost &>/dev/null; then
        gost_version_output=$(gost -v 2>/dev/null || echo "")
        if [[ "$gost_version_output" == *"3."* ]]; then
            gost_version="3"
            echo -e "\e[33mDetected: Gost 3 installed\e[0m"
        else
            gost_version="2"
            echo -e "\e[33mDetected: Gost 2 installed\e[0m"
        fi
    else
        echo -e "\e[31mGost is not installed. Please install it first.\e[0m"
        read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
        return
    fi
    
    read -p "$(echo -e '\e[97mDestination IP: \e[0m')" destination_ip
    read -p "$(echo -e '\e[97mPort(s) (comma separated): \e[0m')" ports
    
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

    create_gost_service "$destination_ip" "$ports" "$protocol" "$gost_version"
    
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
}

# توابع دیگر دقیقاً مانند نسخه قبلی می‌مانند (show_status, auto_restart, etc.)
# فقط تابع main_menu را اضافه می‌کنم:

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
                show_status  # باید تابع show_status از نسخه قبلی باشد
                ;;
            3)
                config_menu  # باید تابع config_menu از نسخه قبلی باشد
                ;;
            4)
                tools_menu   # باید تابع tools_menu از نسخه قبلی باشد
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
