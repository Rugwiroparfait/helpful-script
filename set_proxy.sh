#!/bin/bash

# Function to set proxy
set_proxy() {
    echo "Enter the proxy server address (IP or URL):"
    read proxy_address
    echo "Enter the proxy server port for HTTP/HTTPS:"
    read proxy_port
    echo "Enter the SOCKS proxy port for SSH:"
    read socks_port

    # Set proxy for APT
    sudo touch /etc/apt/apt.conf
    echo "Acquire::http::Proxy \"http://$proxy_address:$proxy_port\";" | sudo tee /etc/apt/apt.conf
    echo "Acquire::https::Proxy \"http://$proxy_address:$proxy_port\";" | sudo tee -a /etc/apt/apt.conf

    # Set proxy for Git
    git config --global http.proxy "http://$proxy_address:$proxy_port"
    git config --global https.proxy "http://$proxy_address:$proxy_port"

    # Set proxy for VSCode
    settings_file="$HOME/.config/Code/User/settings.json"
    mkdir -p "$(dirname "$settings_file")"
    if [ ! -f "$settings_file" ]; then
        echo '{}' > "$settings_file"
    fi
    jq '. + {"http.proxy": "http://'"$proxy_address"':'"$proxy_port"'"}' "$settings_file" > "$settings_file.tmp" && mv "$settings_file.tmp" "$settings_file"

    # Set proxy for SSH
    ssh_config="$HOME/.ssh/config"
    mkdir -p "$(dirname "$ssh_config")"
    if [ ! -f "$ssh_config" ]; then
        touch "$ssh_config"
    fi

    echo -e "Host *\n\tProxyCommand nc -x $proxy_address:$socks_port %h %p" >> "$ssh_config"
    
    echo "Proxy settings have been set for APT, Git, VSCode, and SSH."
}

# Function to unset proxy
unset_proxy() {
    # Unset proxy for APT
    sudo rm -f /etc/apt/apt.conf
    
    # Unset proxy for Git
    git config --global --unset http.proxy
    git config --global --unset https.proxy

    # Unset proxy for VSCode
    settings_file="$HOME/.config/Code/User/settings.json"
    if [ -f "$settings_file" ]; then
        jq 'del(.["http.proxy"])' "$settings_file" > "$settings_file.tmp" && mv "$settings_file.tmp" "$settings_file"
    fi

    # Unset proxy for SSH
    ssh_config="$HOME/.ssh/config"
    if [ -f "$ssh_config" ]; then
        sed -i '/ProxyCommand nc -x/d' "$ssh_config"
    fi

    echo "Proxy settings have been removed for APT, Git, VSCode, and SSH."
}

echo "Do you want to set a proxy? (yes/no)"
read response

if [ "$response" = "yes" ]; then
    set_proxy
elif [ "$response" = "no" ]; then
    unset_proxy
else
    echo "Invalid response. Please enter 'yes' or 'no'."
fi

