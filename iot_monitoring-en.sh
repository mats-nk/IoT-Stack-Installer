#!/bin/bash

#===============================
# IoT Monitoring Stack Installer
# Author : Pak Sormin
# Changes: Mats Karlsson
#===============================

set -e
#-------------------------------------------------
# The cript must be executed as root & OS Ubuntu
#-------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

if [[ ! -f /etc/os-release ]]; then 
    echo "Unknown OS!"
    exit 1
fi

source /etc/os-release
echo "Detected OS : $NAME"

show_menu() {
    echo ""
    echo " ██╗ ██████╗ ████████╗   ███████╗████████╗ █████╗  ██████╗██╗  ██╗"
    echo " ██║██╔═══██╗╚══██╔══╝   ██╔════╝╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝"
    echo " ██║██║   ██║   ██║      ███████╗   ██║   ███████║██║     █████╔╝ "
    echo " ██║██║   ██║   ██║      ╚════██║   ██║   ██╔══██║██║     ██╔═██╗ "
    echo " ██║╚██████╔╝   ██║      ███████║   ██║   ██║  ██║╚██████╗██║  ██╗"
    echo " ╚═╝ ╚═════╝    ╚═╝      ╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝"
    echo ""

    echo "-------- IoT Monitoring Installer --------"
    echo "1. Install MQTT Broker (Mosquitto)"
    echo "2. Install InfluxDB"
    echo "3. Install Grafana"
    echo "4. Install Telegraf"
    echo "0. Exit"
    echo "------------------------------------------"
}

#---------------------------------------------------
# Install MQTT
#---------------------------------------------------
install_mqtt() {
    echo ""
    echo "[INFO] Install MQTT Broker Mosquitto..."

    apt update
    apt install -y mosquitto mosquitto-clients

    systemctl enable mosquitto
    systemctl start mosquitto

    if systemctl is-active --quiet mosquitto; then
        echo "[OK] MQTT Broker installation sucessfull"
    else
        echo "[ERROR] MQTT Broker installation failed"
        exit 1
    fi
}


#---------------------------------------------------
# Install InfluxDB
#---------------------------------------------------
install_influxdb() {
    echo ""
    echo "[INFO] Install InfluxDB 2.x..."
    echo ""

    apt update
    apt install -y curl gnupg lsb-release

    curl --silent --location -O https://repos.influxdata.com/influxdata-archive.key \
        gpg --show-keys --with-fingerprint --with-colons ./influxdata-archive.key 2>&1 \
        | grep -q '^fpr:\+24C975CBA61A024EE1B631787C3D57159FC2F927:$' \
        && cat influxdata-archive.key \
        | gpg --dearmor \
        | sudo tee /etc/apt/keyrings/influxdata-archive.gpg > /dev/null \
        && echo 'deb [signed-by=/etc/apt/keyrings/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' \
        | sudo tee /etc/apt/sources.list.d/influxdata.list

    sudo apt update
    sudo apt install -y influxdb2

    systemctl enable influxdb
    systemctl start influxdb

    if systemctl is-active --quiet influxdb; then
        echo ""
        echo "[OK] InfluxDB berhasil dijalankan"
    else
        echo "[ERROR] InfluxDB gagal dijalankan"
        exit 1
    fi

    echo ""
    echo "=========================================="
    echo "InfluxDB Web UI dapat diakses melalui:"
    echo "http://localhost:8086"
    echo "atau"
    echo "http://<IP_SERVER>:8086"
    echo "=========================================="
}

#-----------------------------------------------------
#  Install Grafana
#-----------------------------------------------------
install_grafana() {
    echo ""
    echo "[INFO] Grafana was successfully installing from the Official APT Repository..."
    echo ""

    # Prerequisite
    apt-get update
    apt-get install -y apt-transport-https wget gnupg

    # Create keyrings directory
    mkdir -p /etc/apt/keyrings

    # Import Grafana GPG key
    wget -q -O - https://apt.grafana.com/gpg.key \
        | gpg --dearmor \
        | tee /etc/apt/keyrings/grafana.gpg > /dev/null

    # Add Grafana stable repository
    echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
        | tee /etc/apt/sources.list.d/grafana.list

    # Update repo and install Grafana OSS
    apt-get update
    apt-get install -y grafana

    # Enable & start service
    systemctl enable grafana-server
    systemctl start grafana-server

    if systemctl is-active --quiet grafana-server; then
        echo "[OK] Grafana executed successfully"
    else
        echo "[ERROR] Grafana failed to run"
        exit 1
    fi

    echo ""
    echo "=========================================="
    echo "Grafana The Web UI can be accessed through:"
    echo "http://localhost:3000"
    echo "Username : admin"
    echo "Password : admin"
    echo "=========================================="
}

#------------------------------------------------------
#  Install Telegraf
#------------------------------------------------------

install_telegraf() {
    echo ""
    echo "[INFO] Install Telegraf (without running the service)..."
    echo ""

    apt update
    apt install -y telegraf

    systemctl stop telegraf >/dev/null 2>&1 || true
    systemctl disable telegraf >/dev/null 2>&1 || true

    echo ""
    echo "=========================================="
    echo "[INFO] Telegraph installed successfully."
    echo "[INFO] Service not executed because the"
    echo "       configure has not yet been created."
    echo "Next step:"
    echo " - Configure input MQTT"
    echo " - Configure output InfluxDB"
    echo " - systemctl start telegraf"
    echo "=========================================="
}


while true; do
    show_menu
    read -p "Install menu: " choice

    case $choice in
        1)
            install_mqtt
            ;;
        2)
            install_influxdb
            ;;
        3)
            install_grafana
            ;;
        4)
            install_telegraf
            ;;
        0)
            echo "Exit..."
            exit 0
            ;;
        *)
            echo "Invalid selection"
            ;;
    esac
done
