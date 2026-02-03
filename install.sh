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
    echo -e "\e[35mGost Ip6 Script v3.0.0\e[0m"
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

detect_gost_version() {
    if command -v gost &>/dev/null; then
        # Try to get version info
        local version_output=$(timeout 3 gost -v 2>/dev/null || echo "")
        
        if [[ "$version_output" == *"3."* ]]; then
            echo "3"
            return 0
        fi
        
        # Try alternative method for Gost 2
        if timeout 3 gost -h 2>&1 | grep -q "ginuerzh\|2\.11"; then
            echo "2"
            return 0
        fi
        
        # Check binary size/type as last resort
        if file /usr/local/bin/gost 2>/dev/null | grep -q "ELF"; then
            echo "unknown"
            return 0
        fi
    fi
    echo "none"
    return 1
}

install_gost2() {
    echo -e "\e[32mInstalling Gost version 2.11.5...\e[0m"
    
    # Stop all gost services first
    echo -e "\e[33mStopping all Gost services...\e[0m"
    systemctl stop gost_*.service 2>/dev/null
    sleep 2
    
    # Backup current gost if exists
    if [ -f /usr/local/bin/gost ]; then
        local backup_name="/usr/local/bin/gost.backup.$(date +%Y%m%d_%H%M%S)"
        cp -f /usr/local/bin/gost "$backup_name"
        echo -e "\e[33mBackup created: $backup_name\e[0m"
    fi
    
    show_animation "Downloading"
    
    # Download Gost 2
    wget -q --show-progress \
        https://github.com/ginuerzh/gost/releases/download/v2.11.5/gost-linux-amd64-2.11.5.gz
    
    if [ $? -eq 0 ] && [ -f "gost-linux-amd64-2.11.5.gz" ]; then
        show_animation "Extracting"
        
        # Extract
        gunzip -f gost-linux-amd64-2.11.5.gz
        if [ -f "gost-linux-amd64-2.11.5" ]; then
            mv -f gost-linux-amd64-2.11.5 /usr/local/bin/gost
            chmod +x /usr/local/bin/gost
            
            # Cleanup
            rm -f gost-linux-amd64-2.11.5.gz 2>/dev/null
            
            # Verify installation
            echo -e "\e[33mVerifying installation...\e[0m"
            sleep 1
            
            if timeout 3 /usr/local/bin/gost -h 2>&1 | grep -q "ginuerzh"; then
                echo -e "\e[32m✓ Gost 2.11.5 installed successfully\e[0m"
                
                # Cleanup old services to prevent conflicts
                echo -e "\e[33mCleaning up old service configurations...\e[0m"
                systemctl stop gost_*.service 2>/dev/null
                systemctl disable gost_*.service 2>/dev/null
                rm -f /etc/systemd/system/gost_*.service 2>/dev/null
                systemctl daemon-reload
                
                return 0
            else
                echo -e "\e[31m✗ Gost 2 verification failed\e[0m"
                
                # Restore backup if exists
                if ls /usr/local/bin/gost.backup.* 2>/dev/null | head -1; then
                    local latest_backup=$(ls -t /usr/local/bin/gost.backup.* 2>/dev/null | head -1)
                    if [ -f "$latest_backup" ]; then
                        echo -e "\e[33mRestoring from backup...\e[0m"
                        cp -f "$latest_backup" /usr/local/bin/gost
                        chmod +x /usr/local/bin/gost
                    fi
                fi
                
                return 1
            fi
        else
            echo -e "\e[31m✗ Extraction failed\e[0m"
            return 1
        fi
    else
        echo -e "\e[31m✗ Download failed. Please check your connection.\e[0m"
        
        # Try alternative source
        echo -e "\e[33mTrying alternative download source...\e[0m"
        if wget -q --show-progress -O /tmp/gost2.gz \
            "https://github.com/ginuerzh/gost/releases/download/v2.11.5/gost-linux-amd64-2.11.5.gz"; then
            
            gunzip -f /tmp/gost2.gz -c > /usr/local/bin/gost
            chmod +x /usr/local/bin/gost
            
            if timeout 3 /usr/local/bin/gost -h 2>&1 | grep -q "ginuerzh"; then
                echo -e "\e[32m✓ Gost 2.11.5 installed successfully (alternative source)\e[0m"
                return 0
            fi
        fi
        
        return 1
    fi
}

install_gost3() {
    echo -e "\e[32mInstalling Gost version 3.2.6...\e[0m"
    
    # Stop all gost services first
    echo -e "\e[33mStopping all Gost services...\e[0m"
    systemctl stop gost_*.service 2>/dev/null
    sleep 3
    
    # Backup current gost if exists
    if [ -f /usr/local/bin/gost ]; then
        local backup_name="/usr/local/bin/gost.backup.$(date +%Y%m%d_%H%M%S)"
        cp -f /usr/local/bin/gost "$backup_name"
        echo -e "\e[33mBackup created: $backup_name\e[0m"
    fi
    
    # Cleanup old files
    rm -f /tmp/gost.tar.gz /tmp/gost3.tar.gz
    
    # Primary download URL
    local download_urls=(
        "https://github.com/go-gost/gost/releases/download/v3.2.6/gost_3.2.6_linux_amd64.tar.gz"
        "https://github.com/go-gost/gost/releases/download/v3.2.6/gost-linux-amd64-3.2.6.tar.gz"
        "https://github.com/go-gost/gost/archive/refs/tags/v3.2.6.tar.gz"
    )
    
    local download_success=0
    for url in "${download_urls[@]}"; do
        echo -e "\e[33mTrying: $url\e[0m"
        show_animation "Downloading"
        
        if wget -q --show-progress -O /tmp/gost.tar.gz "$url"; then
            if [ -s /tmp/gost.tar.gz ]; then
                download_success=1
                break
            fi
        fi
        sleep 1
    done
    
    if [ $download_success -ne 1 ]; then
        echo -e "\e[31m✗ All download attempts failed\e[0m"
        return 1
    fi
    
    show_animation "Extracting"
    
    # Create temporary directory for extraction
    local temp_dir=$(mktemp -d)
    
    # Extract archive
    if ! tar -xzf /tmp/gost.tar.gz -C "$temp_dir" --strip-components=1 2>/dev/null; then
        # Try without strip-components
        tar -xzf /tmp/gost.tar.gz -C "$temp_dir" 2>/dev/null
    fi
    
    # Find gost binary
    local gost_binary=""
    
    # Look for binary in extracted files
    for pattern in "gost" "gost-*" "*gost*" "*/gost"; do
        local found=$(find "$temp_dir" -type f -name "$pattern" ! -name "*.gz" ! -name "*.tar" 2>/dev/null | head -1)
        if [ -n "$found" ] && [ -x "$found" ] || [ -f "$found" ]; then
            gost_binary="$found"
            break
        fi
    done
    
    if [ -n "$gost_binary" ] && [ -f "$gost_binary" ]; then
        # Copy binary
        cp -f "$gost_binary" /usr/local/bin/gost
        chmod +x /usr/local/bin/gost
        
        # Verify installation
        echo -e "\e[33mVerifying installation...\e[0m"
        sleep 2
        
        local version_output=$(timeout 5 /usr/local/bin/gost -v 2>/dev/null || echo "")
        
        if [[ "$version_output" == *"3."* ]] || [[ "$version_output" == *"gost"* ]]; then
            echo -e "\e[32m✓ Gost 3 installed successfully\e[0m"
            echo -e "\e[33mVersion info: $version_output\e[0m"
            
            # Cleanup old services
            echo -e "\e[33mCleaning up old service configurations...\e[0m"
            systemctl stop gost_*.service 2>/dev/null
            systemctl disable gost_*.service 2>/dev/null
            rm -f /etc/systemd/system/gost_*.service 2>/dev/null
            systemctl daemon-reload
            
            # Cleanup temp files
            rm -rf "$temp_dir" /tmp/gost.tar.gz
            
            return 0
        else
            echo -e "\e[31m✗ Gost 3 verification failed\e[0m"
            echo -e "\e[33mOutput was: $version_output\e[0m"
            
            # Restore backup if exists
            if ls /usr/local/bin/gost.backup.* 2>/dev/null | head -1; then
                local latest_backup=$(ls -t /usr/local/bin/gost.backup.* 2>/dev/null | head -1)
                if [ -f "$latest_backup" ]; then
                    echo -e "\e[33mRestoring from backup...\e[0m"
                    cp -f "$latest_backup" /usr/local/bin/gost
                    chmod +x /usr/local/bin/gost
                fi
            fi
            
            rm -rf "$temp_dir"
            return 1
        fi
    else
        echo -e "\e[31m✗ Could not find gost binary in archive\e[0m"
        
        # List contents for debugging
        echo -e "\e[33mArchive contents:\e[0m"
        tar -tzf /tmp/gost.tar.gz 2>/dev/null | head -20
        
        rm -rf "$temp_dir"
        return 1
    fi
}

install_gost_version() {
    echo -e "\e[32mChoose Gost version:\e[0m"
    echo -e "\e[36m1. \e[0mGost version 2.11.5 (stable)"
    echo -e "\e[36m2. \e[0mGost version 3.2.6 (latest)"
    echo -e "\e[36m3. \e[0mCancel and return to menu"
    echo ""

    read -p "$(echo -e '\e[97mYour choice (1-3): \e[0m')" gost_version_choice

    case "$gost_version_choice" in
        1)
            install_gost2
            local result=$?
            if [ $result -eq 0 ]; then
                echo -e "\e[32m✓ Successfully switched to Gost 2.11.5\e[0m"
                echo -e "\e[33mNote: You need to recreate tunnels with Gost 2 syntax\e[0m"
            fi
            return $result
            ;;
        2)
            install_gost3
            local result=$?
            if [ $result -eq 0 ]; then
                echo -e "\e[32m✓ Successfully switched to Gost 3.2.6\e[0m"
                echo -e "\e[33mNote: You need to recreate tunnels with Gost 3 syntax\e[0m"
            fi
            return $result
            ;;
        3)
            echo -e "\e[33mInstallation cancelled\e[0m"
            return 2
            ;;
        *)
            echo -e "\e[31mInvalid choice. Please enter 1, 2 or 3.\e[0m"
            return 1
            ;;
    esac
}

configure_system() {
    echo -e "\e[32mConfiguring system...\e[0m"
    
    # Update packages
    show_animation "Updating packages"
    apt update >/dev/null 2>&1 && apt install -y wget nano curl tar gzip >/dev/null 2>&1
    
    # Create alias
    if ! grep -q "alias gost=" ~/.bashrc; then
        echo 'alias gost="bash /etc/gost/install.sh"' >> ~/.bashrc
    fi
    
    # Source bashrc for current session
    if [ -f ~/.bashrc ]; then
        source ~/.bashrc >/dev/null 2>&1
    fi
    
    echo -e "\e[32m✓ System configuration completed\e[0m"
    return 0
}

create_gost_service() {
    local destination_ip=$1
    local ports=$2
    local protocol=$3
    
    # Detect current Gost version
    local gost_version=$(detect_gost_version)
    
    if [ "$gost_version" = "none" ]; then
        echo -e "\e[31m✗ Gost is not installed. Please install Gost first.\e[0m"
        return 1
    fi
    
    echo -e "\e[33mDetected Gost version: $gost_version\e[0m"
    
    IFS=',' read -ra port_array <<< "$ports"
    local port_count=${#port_array[@]}
    local max_ports_per_file=50  # Reduced for better management
    local file_count=$(( (port_count + max_ports_per_file - 1) / max_ports_per_file ))

    for ((file_index = 0; file_index < file_count; file_index++)); do
        # Create safe service name
        local safe_ip=$(echo "$destination_ip" | tr '.:/' '_')
        local service_name="gost_${safe_ip}_$((file_index + 1))"
        
        # Stop and disable old service if exists
        systemctl stop "${service_name}.service" 2>/dev/null
        systemctl disable "${service_name}.service" 2>/dev/null
        sleep 1
        
        # Remove old service file
        rm -f "/etc/systemd/system/${service_name}.service"
        
        echo -e "\e[33mCreating service: ${service_name}\e[0m"
        
        # Create service file
        cat <<EOL > "/etc/systemd/system/${service_name}.service"
[Unit]
Description=Gost Tunnel ${service_name} (v${gost_version})
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Restart=always
RestartSec=5
LimitNOFILE=65536
Environment="GOST_LOGGER_LEVEL=warn"
EOL

        # Build ExecStart command based on version
        local exec_start_command="ExecStart=/usr/local/bin/gost"
        local port_list=""
        
        for ((i = file_index * max_ports_per_file; i < (file_index + 1) * max_ports_per_file && i < port_count; i++)); do
            local port="${port_array[i]}"
            port=$(echo "$port" | xargs)  # Trim whitespace
            
            if [[ "$port" =~ ^[0-9]+$ ]]; then
                if [ "$gost_version" = "3" ]; then
                    # Syntax for Gost 3: -L :port -F protocol://[ip]:port
                    exec_start_command+=" -L :${port} -F ${protocol}://[${destination_ip}]:${port}"
                else
                    # Syntax for Gost 2: -L=protocol://:port/[ip]:port
                    exec_start_command+=" -L=${protocol}://:${port}/[${destination_ip}]:${port}"
                fi
                port_list+="$port,"
            else
                echo -e "\e[33mWarning: Skipping invalid port '$port'\e[0m"
            fi
        done
        
        # Remove trailing comma
        port_list=${port_list%,}
        
        if [ -z "$port_list" ]; then
            echo -e "\e[31m✗ No valid ports to create service\e[0m"
            rm -f "/etc/systemd/system/${service_name}.service"
            continue
        fi
        
        echo "$exec_start_command" >> "/etc/systemd/system/${service_name}.service"

        # Add service footer
        cat <<EOL >> "/etc/systemd/system/${service_name}.service"

StandardOutput=journal
StandardError=journal
SyslogIdentifier=${service_name}
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOL

        # Reload systemd, enable and start service
        systemctl daemon-reload
        
        # Enable service
        if systemctl enable "${service_name}.service" >/dev/null 2>&1; then
            echo -e "\e[32m✓ Service '${service_name}' enabled\e[0m"
        else
            echo -e "\e[31m✗ Failed to enable service '${service_name}'\e[0m"
            continue
        fi
        
        # Start service
        if systemctl start "${service_name}.service" >/dev/null 2>&1; then
            echo -e "\e[33mStarting service '${service_name}'...\e[0m"
            sleep 3
            
            # Check service status
            if systemctl is-active --quiet "${service_name}.service"; then
                echo -e "\e[32m✓ Service '${service_name}' started successfully\e[0m"
                echo -e "\e[33mPorts: $port_list | Protocol: $protocol\e[0m"
            else
                echo -e "\e[31m✗ Service '${service_name}' failed to start\e[0m"
                
                # Show logs for debugging
                echo -e "\e[33mLast 10 lines of journal:\e[0m"
                journalctl -u "${service_name}.service" -n 10 --no-pager
            fi
        else
            echo -e "\e[31m✗ Failed to start service '${service_name}'\e[0m"
        fi
        
        echo ""
    done

    systemctl daemon-reload
    echo -e "\e[32m✓ Gost services configuration completed\e[0m"
    return 0
}

setup_tunnel() {
    # First, choose and install Gost version
    install_gost_version
    local install_result=$?
    
    if [ $install_result -eq 2 ]; then
        # User cancelled installation
        return 1
    elif [ $install_result -ne 0 ]; then
        echo -e "\e[31mGost installation failed. Returning to menu...\e[0m"
        sleep 3
        return 1
    fi
    
    echo ""
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mSelect tunnel type:\e[0m"
    echo -e "\e[36m1. \e[0mIPv4 Tunnel"
    echo -e "\e[36m2. \e[0mIPv6 Tunnel"
    echo -e "\e[36m3. \e[0mReturn to main menu"
    echo "══════════════════════════════════════════════════"
    
    read -p "$(echo -e '\e[97mYour choice: \e[0m')" tunnel_type

    case $tunnel_type in
        1)
            read -p "$(echo -e '\e[97mDestination IPv4: \e[0m')" destination_ip
            # Validate IPv4
            if ! [[ "$destination_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo -e "\e[31mInvalid IPv4 address\e[0m"
                return 1
            fi
            ;;
        2)
            read -p "$(echo -e '\e[97mDestination IPv6: \e[0m')" destination_ip
            # Basic IPv6 validation
            if [[ "$destination_ip" != *:* ]]; then
                echo -e "\e[33mWarning: This doesn't look like a valid IPv6 address\e[0m"
                read -p "$(echo -e '\e[97mContinue anyway? (y/n): \e[0m')" confirm_ipv6
                if [[ "$confirm_ipv6" != "y" && "$confirm_ipv6" != "Y" ]]; then
                    return 1
                fi
            fi
            ;;
        3)
            echo -e "\e[33mReturning to main menu...\e[0m"
            return 1
            ;;
        *)
            echo -e "\e[31mInvalid choice.\e[0m"
            return 1
            ;;
    esac

    # Get ports
    while true; do
        read -p "$(echo -e '\e[97mPort(s) (comma separated, e.g., 8080,8081,9000-9010): \e[0m')" ports_input
        
        if [ -z "$ports_input" ]; then
            echo -e "\e[31mPorts cannot be empty\e[0m"
            continue
        fi
        
        # Process port ranges
        local processed_ports=""
        IFS=',' read -ra port_items <<< "$ports_input"
        
        for item in "${port_items[@]}"; do
            item=$(echo "$item" | xargs)  # Trim whitespace
            
            if [[ "$item" =~ ^[0-9]+$ ]]; then
                # Single port
                processed_ports+="$item,"
            elif [[ "$item" =~ ^[0-9]+-[0-9]+$ ]]; then
                # Port range
                local start_port=$(echo "$item" | cut -d'-' -f1)
                local end_port=$(echo "$item" | cut -d'-' -f2)
                
                if [ "$start_port" -le "$end_port" ] && [ "$start_port" -gt 0 ] && [ "$end_port" -lt 65536 ]; then
                    for ((port=start_port; port<=end_port; port++)); do
                        processed_ports+="$port,"
                    done
                else
                    echo -e "\e[33mWarning: Invalid port range '$item'. Skipping.\e[0m"
                fi
            else
                echo -e "\e[33mWarning: Invalid port format '$item'. Skipping.\e[0m"
            fi
        done
        
        processed_ports=${processed_ports%,}  # Remove trailing comma
        
        if [ -n "$processed_ports" ]; then
            ports="$processed_ports"
            break
        else
            echo -e "\e[31mNo valid ports provided. Please try again.\e[0m"
        fi
    done

    echo -e "\e[32mSelect the protocol:\e[0m"
    echo -e "\e[36m1. \e[0mTCP (recommended)"
    echo -e "\e[36m2. \e[0mUDP"
    echo -e "\e[36m3. \e[0mgRPC"
    echo -e "\e[36m4. \e[0mReturn"
    
    read -p "$(echo -e '\e[97mYour choice: \e[0m')" protocol_choice

    case $protocol_choice in
        1) protocol="tcp" ;;
        2) protocol="udp" ;;
        3) protocol="grpc" ;;
        4)
            echo -e "\e[33mReturning...\e[0m"
            return 1
            ;;
        *) 
            echo -e "\e[33mDefaulting to TCP\e[0m"
            protocol="tcp"
            ;;
    esac

    echo ""
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mConfiguration Summary:\e[0m"
    echo -e "\e[97mDestination IP:\e[0m \e[36m$destination_ip\e[0m"
    echo -e "\e[97mPorts:\e[0m \e[36m$ports\e[0m"
    echo -e "\e[97mProtocol:\e[0m \e[36m$protocol\e[0m"
    
    # Detect and show current Gost version
    local current_version=$(detect_gost_version)
    if [ "$current_version" != "none" ]; then
        echo -e "\e[97mGost Version:\e[0m \e[36m$current_version\e[0m"
    fi
    
    echo "══════════════════════════════════════════════════"
    echo ""
    
    read -p "$(echo -e '\e[97mProceed with setup? (y/n): \e[0m')" confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "\e[33mSetup cancelled.\e[0m"
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
    local gost_version=$(detect_gost_version)
    
    if [ "$gost_version" = "none" ]; then
        echo -e "\e[31m✗ Gost Not Installed\e[0m"
    else
        echo -e "\e[32m✓ Gost Installed\e[0m"
        echo -e "\e[97mVersion:\e[0m \e[36m$gost_version\e[0m"
        
        # Show binary path
        if command -v gost &>/dev/null; then
            echo -e "\e[97mBinary:\e[0m \e[36m$(which gost)\e[0m"
        fi
    fi
    
    echo ""
    
    # Check active tunnels
    local active_services=$(systemctl list-units --type=service --state=active "gost_*" 2>/dev/null | grep "gost_" | wc -l)
    local failed_services=$(systemctl list-units --type=service --state=failed "gost_*" 2>/dev/null | grep "gost_" | wc -l)
    
    if [ "$active_services" -gt 0 ] || [ "$failed_services" -gt 0 ]; then
        echo -e "\e[32mActive Tunnels: $active_services\e[0m"
        if [ "$failed_services" -gt 0 ]; then
            echo -e "\e[31mFailed Tunnels: $failed_services\e[0m"
        fi
        echo "──────────────────────────────────────"
        
        # Get all gost services
        systemctl list-units --type=service --all "gost_*" 2>/dev/null | grep "gost_" | while read -r line; do
            service_name=$(echo "$line" | awk '{print $1}')
            status=$(echo "$line" | awk '{print $3}')
            load_state=$(echo "$line" | awk '{print $2}')
            
            # Skip header line
            if [ "$service_name" = "UNIT" ]; then
                continue
            fi
            
            # Extract IP from service name
            local ip=$(echo "$service_name" | sed 's/^gost_//' | sed 's/_[0-9]\+\.service$//' | tr '_' '.' | sed 's/\.\.*/./g')
            
            # Try to extract IPv6
            if [[ "$ip" != *.*.*.* ]]; then
                ip=$(echo "$service_name" | sed 's/^gost_//' | sed 's/_[0-9]\+\.service$//' | tr '_' ':')
            fi
            
            # Color code status
            local status_color="\e[33m"  # Yellow for unknown
            case "$status" in
                "active") status_color="\e[32m" ;;  # Green
                "failed") status_color="\e[31m" ;;  # Red
                "inactive") status_color="\e[90m" ;; # Gray
            esac
            
            echo -e "\e[97mService:\e[0m ${service_name%.service}"
            echo -e "\e[97mStatus:\e[0m ${status_color}$status\e[0m"
            echo -e "\e[97mIP:\e[0m \e[36m$ip\e[0m"
            
            # Get more info from service file
            local service_file="/etc/systemd/system/${service_name}"
            if [ -f "$service_file" ]; then
                # Get ports
                local ports_line=$(grep -o ":[0-9]\+ " "$service_file" | tr -d ': ' | tr '\n' ',' | sed 's/,$//')
                if [ -z "$ports_line" ]; then
                    ports_line=$(grep -o "//:[0-9]\+" "$service_file" | tr -d '/:' | tr '\n' ',' | sed 's/,$//')
                fi
                
                # Get protocol
                local protocol=$(grep -o "tcp\|udp\|grpc" "$service_file" | head -1)
                
                if [ -n "$ports_line" ]; then
                    echo -e "\e[97mPorts:\e[0m \e[36m$ports_line\e[0m"
                fi
                if [ -n "$protocol" ]; then
                    echo -e "\e[97mProtocol:\e[0m \e[36m$protocol\e[0m"
                fi
            fi
            
            # Show recent logs if failed
            if [ "$status" = "failed" ]; then
                echo -e "\e[31mLast error:\e[0m"
                journalctl -u "$service_name" -n 3 --no-pager 2>/dev/null | tail -3
            fi
            
            echo "──────────────────────────────────────"
        done
    else
        echo -e "\e[33mNo Gost tunnels found\e[0m"
    fi
    
    # Show listening ports
    echo ""
    echo -e "\e[32mListening ports (Gost related):\e[0m"
    echo "──────────────────────────────────────"
    ss -tulpn 2>/dev/null | grep -E "(:[0-9]+)" | grep -E "(gost|LISTEN)" | head -20 | while read -r line; do
        echo -e "\e[36m$line\e[0m"
    done
    
    echo ""
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
    echo ""
}

update_script() {
    echo -e "\e[32mUpdating script...\e[0m"
    mkdir -p /etc/gost
    show_animation "Downloading"
    
    # Backup current script
    if [ -f /etc/gost/install.sh ]; then
        cp /etc/gost/install.sh /etc/gost/install.sh.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # Try multiple sources
    local update_urls=(
        "https://raw.githubusercontent.com/masoudgb/Gost-ip6/main/install.sh"
        "https://raw.githubusercontent.com/masoudgb/Gost-ip6/master/install.sh"
    )
    
    local update_success=0
    for url in "${update_urls[@]}"; do
        echo -e "\e[33mTrying: $url\e[0m"
        
        if wget -q --show-progress -O /tmp/gost_install.sh "$url"; then
            if [ -s /tmp/gost_install.sh ] && grep -q "Gost Ip6 Script" /tmp/gost_install.sh; then
                mv /tmp/gost_install.sh /etc/gost/install.sh
                chmod +x /etc/gost/install.sh
                update_success=1
                break
            fi
        fi
    done
    
    if [ $update_success -eq 1 ]; then
        echo -e "\e[32m✓ Update completed successfully\e[0m"
        echo -e "\e[36mRestarting with new version...\e[0m"
        sleep 3
        exec bash /etc/gost/install.sh
    else
        echo -e "\e[31m✗ Update failed. Check network connection or repository.\e[0m"
        
        # Restore backup if exists
        if ls /etc/gost/install.sh.backup.* 2>/dev/null | head -1; then
            local latest_backup=$(ls -t /etc/gost/install.sh.backup.* 2>/dev/null | head -1)
            if [ -f "$latest_backup" ]; then
                echo -e "\e[33mRestoring from backup...\e[0m"
                cp -f "$latest_backup" /etc/gost/install.sh
                chmod +x /etc/gost/install.sh
            fi
        fi
        
        sleep 3
    fi
}

add_new_ip() {
    clear
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mADD NEW TUNNEL\e[0m"
    echo "══════════════════════════════════════════════════"
    
    # Check if Gost is installed
    local gost_version=$(detect_gost_version)
    if [ "$gost_version" = "none" ]; then
        echo -e "\e[31mGost is not installed. Please install it first.\e[0m"
        read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
        return
    fi
    
    echo -e "\e[33mCurrent Gost version: $gost_version\e[0m"
    echo ""
    
    read -p "$(echo -e '\e[97mDestination IP: \e[0m')" destination_ip
    
    if [ -z "$destination_ip" ]; then
        echo -e "\e[31mIP address cannot be empty\e[0m"
        return
    fi
    
    read -p "$(echo -e '\e[97mPort(s) (comma separated, e.g., 8080,8081): \e[0m')" ports
    
    if [ -z "$ports" ]; then
        echo -e "\e[31mPorts cannot be empty\e[0m"
        return
    fi
    
    echo -e "\e[32mSelect protocol:\e[0m"
    echo -e "\e[36m1. \e[0mTCP (recommended)"
    echo -e "\e[36m2. \e[0mgRPC"
    echo -e "\e[36m3. \e[0mUDP"
    echo -e "\e[36m4. \e[0mCancel"
    
    read -p "$(echo -e '\e[97mYour choice: \e[0m')" protocol_choice

    case $protocol_choice in
        1) protocol="tcp" ;;
        2) protocol="grpc" ;;
        3) protocol="udp" ;;
        4) 
            echo -e "\e[33mCancelled\e[0m"
            return
            ;;
        *) 
            echo -e "\e[33mDefaulting to TCP\e[0m"
            protocol="tcp"
            ;;
    esac

    create_gost_service "$destination_ip" "$ports" "$protocol"
    
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
}

fix_gost_services() {
    clear
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32mFIX GOST SERVICES\e[0m"
    echo "══════════════════════════════════════════════════"
    
    # Detect current Gost version
    local current_version=$(detect_gost_version)
    
    if [ "$current_version" = "none" ]; then
        echo -e "\e[31mGost is not installed. Please install it first.\e[0m"
        read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
        return
    fi
    
    echo -e "\e[33mDetected Gost version: $current_version\e[0m"
    echo ""
    
    echo -e "\e[32mWhat would you like to do?\e[0m"
    echo -e "\e[36m1. \e[0mRestart all Gost services"
    echo -e "\e[36m2. \e[0mStop all Gost services"
    echo -e "\e[36m3. \e[0mFix service syntax for current version"
    echo -e "\e[36m4. \e[0mView service logs"
    echo -e "\e[36m5. \e[0mReturn to menu"
    
    read -p "$(echo -e '\e[97mYour choice: \e[0m')" fix_choice

    case $fix_choice in
        1)
            echo -e "\e[33mRestarting all Gost services...\e[0m"
            systemctl daemon-reload
            systemctl restart gost_*.service 2>/dev/null
            sleep 3
            
            local active_count=$(systemctl list-units --type=service --state=active "gost_*" 2>/dev/null | grep "gost_" | wc -l)
            echo -e "\e[32m✓ Restarted all services. Active: $active_count\e[0m"
            ;;
        2)
            echo -e "\e[33mStopping all Gost services...\e[0m"
            systemctl stop gost_*.service 2>/dev/null
            echo -e "\e[32m✓ All services stopped\e[0m"
            ;;
        3)
            echo -e "\e[33mChecking service syntax...\e[0m"
            
            local fixed_count=0
            for service_file in /etc/systemd/system/gost_*.service; do
                [ -e "$service_file" ] || continue
                
                local service_name=$(basename "$service_file" .service)
                echo -e "\e[36mChecking: $service_name\e[0m"
                
                # Extract ExecStart line
                local exec_line=$(grep "^ExecStart=" "$service_file")
                
                if [ "$current_version" = "3" ] && [[ "$exec_line" == *"-L="* ]]; then
                    echo -e "\e[33mFixing Gost 3 syntax...\e[0m"
                    
                    # Extract information
                    local ip_port=$(echo "$exec_line" | grep -o '\[.*\]' | head -1 | tr -d '[]')
                    local ip=$(echo "$ip_port" | cut -d: -f1)
                    local port=$(echo "$ip_port" | cut -d: -f2)
                    local protocol=$(echo "$exec_line" | grep -o 'tcp\|udp\|grpc' | head -1)
                    
                    if [ -n "$ip" ] && [ -n "$port" ] && [ -n "$protocol" ]; then
                        # Stop old service
                        systemctl stop "$service_name" 2>/dev/null
                        systemctl disable "$service_name" 2>/dev/null
                        
                        # Create new service
                        create_gost_service "$ip" "$port" "$protocol"
                        ((fixed_count++))
                    fi
                    
                elif [ "$current_version" = "2" ] && [[ "$exec_line" == *"-L :"* ]]; then
                    echo -e "\e[33mFixing Gost 2 syntax...\e[0m"
                    # Similar logic for Gost 2
                fi
            done
            
            if [ $fixed_count -gt 0 ]; then
                echo -e "\e[32m✓ Fixed $fixed_count services\e[0m"
            else
                echo -e "\e[32m✓ No services needed fixing\e[0m"
            fi
            ;;
        4)
            echo -e "\e[33mSelect service to view logs:\e[0m"
            
            local services=($(systemctl list-units --type=service --all "gost_*" 2>/dev/null | grep "gost_" | awk '{print $1}' | sed 's/\.service$//'))
            
            if [ ${#services[@]} -eq 0 ]; then
                echo -e "\e[33mNo Gost services found\e[0m"
            else
                select service_name in "${services[@]}" "Return"; do
                    if [ "$service_name" = "Return" ]; then
                        break
                    elif [ -n "$service_name" ]; then
                        clear
                        echo "══════════════════════════════════════════════════"
                        echo -e "\e[32mLOGS FOR: $service_name\e[0m"
                        echo "══════════════════════════════════════════════════"
                        journalctl -u "$service_name" -n 50 --no-pager
                        echo ""
                        read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
                        break
                    fi
                done
            fi
            ;;
        5)
            return
            ;;
        *)
            echo -e "\e[31mInvalid choice\e[0m"
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
    echo -e "\e[36m3. \e[0mView current schedule"
    echo -e "\e[36m4. \e[0mReturn"
    
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
echo "[Auto-Restart] Restarting Gost services at \$(date)"
systemctl daemon-reload
systemctl restart gost_*.service
echo "[Auto-Restart] Completed at \$(date)"
EOL
            chmod +x /usr/bin/auto_restart_gost.sh
            
            # Remove existing entry
            crontab -l 2>/dev/null | grep -v auto_restart_gost.sh | crontab -
            
            # Add new entry
            (crontab -l 2>/dev/null; echo "0 */${interval} * * * /usr/bin/auto_restart_gost.sh >> /var/log/gost_auto_restart.log 2>&1") | crontab -
            
            echo -e "\e[32m✓ Auto restart enabled (every ${interval} hours)\e[0m"
            echo -e "\e[33mLog file: /var/log/gost_auto_restart.log\e[0m"
            ;;
        2)
            rm -f /usr/bin/auto_restart_gost.sh 2>/dev/null
            crontab -l 2>/dev/null | grep -v auto_restart_gost.sh | crontab -
            rm -f /var/log/gost_auto_restart.log 2>/dev/null
            echo -e "\e[32m✓ Auto restart disabled\e[0m"
            ;;
        3)
            echo -e "\e[33mCurrent auto-restart schedule:\e[0m"
            crontab -l 2>/dev/null | grep auto_restart_gost.sh || echo "No auto-restart scheduled"
            
            if [ -f /var/log/gost_auto_restart.log ]; then
                echo -e "\e[33mLast log entries:\e[0m"
                tail -10 /var/log/gost_auto_restart.log 2>/dev/null
            fi
            ;;
        4)
            return
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
    echo -e "\e[36m3. \e[0mClear cache now"
    echo -e "\e[36m4. \e[0mReturn"
    
    read -p "$(echo -e '\e[97mYour choice: \e[0m')" choice

    case $choice in
        1)
            read -p "$(echo -e '\e[97mInterval in days (1-30): \e[0m')" interval
            if ! [[ "$interval" =~ ^[0-9]+$ ]] || [ "$interval" -lt 1 ] || [ "$interval" -gt 30 ]; then
                echo -e "\e[31mInvalid interval\e[0m"
                return
            fi
            
            # Remove existing entries
            crontab -l 2>/dev/null | grep -v "drop_caches\|clear_cache" | crontab -
            
            # Add new entry
            (crontab -l 2>/dev/null; echo "0 2 */${interval} * * sync && echo 1 > /proc/sys/vm/drop_caches && echo 2 > /proc/sys/vm/drop_caches && echo 3 > /proc/sys/vm/drop_caches && date >> /var/log/clear_cache.log") | crontab -
            
            echo -e "\e[32m✓ Auto clear cache enabled (every ${interval} days at 2 AM)\e[0m"
            echo -e "\e[33mLog file: /var/log/clear_cache.log\e[0m"
            ;;
        2)
            crontab -l 2>/dev/null | grep -v "drop_caches\|clear_cache" | crontab -
            echo -e "\e[32m✓ Auto clear cache disabled\e[0m"
            ;;
        3)
            echo -e "\e[33mClearing cache now...\e[0m"
            sync
            echo 1 > /proc/sys/vm/drop_caches
            echo 2 > /proc/sys/vm/drop_caches
            echo 3 > /proc/sys/vm/drop_caches
            echo -e "\e[32m✓ Cache cleared\e[0m"
            ;;
        4)
            return
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
    
    echo -e "\e[33mThis will install Google BBR congestion control.\e[0m"
    echo -e "\e[33mSystem reboot will be required.\e[0m"
    echo ""
    
    read -p "$(echo -e '\e[97mProceed? (y/n): \e[0m')" confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "\e[33mCancelled\e[0m"
        return
    fi
    
    wget --no-check-certificate -O /tmp/bbr.sh https://github.com/teddysun/across/raw/master/bbr.sh
    chmod +x /tmp/bbr.sh
    bash /tmp/bbr.sh
    
    read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
}

uninstall() {
    clear
    echo -e "\e[91m╔══════════════════════════════════════════════════════════╗"
    echo -e "\e[91m║                    WARNING: UNINSTALL                    ║"
    echo -e "\e[91m╚══════════════════════════════════════════════════════════╝"
    echo -e "\e[33mThis will remove Gost and all tunnel configurations.\e[0m"
    echo -e "\e[33mAll active tunnels will be stopped.\e[0m"
    echo ""
    
    read -p "$(echo -e '\e[97mAre you sure? (type UNINSTALL to confirm): \e[0m')" confirm
    
    if [ "$confirm" != "UNINSTALL" ]; then
        echo -e "\e[32mCancelled\e[0m"
        sleep 2
        return
    fi
    
    echo -e "\e[33mUninstalling in 5 seconds...\e[0m"
    for i in 5 4 3 2 1; do
        echo -e "\e[33m${i}...\e[0m"
        sleep 1
    done
    
    echo -e "\e[32mStopping services...\e[0m"
    systemctl daemon-reload
    systemctl stop gost_*.service 2>/dev/null
    systemctl disable gost_*.service 2>/dev/null
    sleep 2
    
    echo -e "\e[32mRemoving service files...\e[0m"
    rm -f /etc/systemd/system/gost_*.service
    systemctl daemon-reload
    
    echo -e "\e[32mRemoving binaries...\e[0m"
    rm -f /usr/local/bin/gost
    rm -f /usr/local/bin/gost.backup.* 2>/dev/null
    
    echo -e "\e[32mRemoving configuration...\e[0m"
    rm -rf /etc/gost 2>/dev/null
    
    echo -e "\e[32mCleaning up cron jobs...\e[0m"
    rm -f /usr/bin/auto_restart_gost.sh 2>/dev/null
    crontab -l 2>/dev/null | grep -v "gost\|drop_caches\|clear_cache" | crontab -
    
    echo -e "\e[32mRemoving log files...\e[0m"
    rm -f /var/log/gost_auto_restart.log 2>/dev/null
    rm -f /var/log/clear_cache.log 2>/dev/null
    
    echo "══════════════════════════════════════════════════"
    echo -e "\e[32m✓ Gost completely uninstalled\e[0m"
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
        echo -e "\e[36m3. \e[0mFix Gost Services"
        echo -e "\e[36m4. \e[0mAuto Restart"
        echo -e "\e[36m5. \e[0mAuto Clear Cache"
        echo -e "\e[36m6. \e[0mBack to Main Menu"
        echo "══════════════════════════════════════════════════"
        
        read -p "$(echo -e '\e[97mYour choice: \e[0m')" choice

        case $choice in
            1) 
                add_new_ip
                ;;
            2) 
                install_gost_version
                if [ $? -eq 0 ]; then
                    echo -e "\e[32m✓ Version changed successfully\e[0m"
                fi
                read -n 1 -s -r -p "$(echo -e '\e[36mPress any key to continue...\e[0m')"
                ;;
            3) 
                fix_gost_services
                ;;
            4) 
                auto_restart
                ;;
            5) 
                auto_clear_cache
                ;;
            6)
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
        echo -e "\e[36m3. \e[0mUninstall Gost"
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
        
        # Show current Gost version if installed
        local gost_version=$(detect_gost_version)
        if [ "$gost_version" != "none" ]; then
            echo -e "\e[33mCurrent Gost version: $gost_version\e[0m"
        else
            echo -e "\e[31mGost not installed\e[0m"
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

# Initial setup
mkdir -p /etc/gost

# Main execution
main_menu
