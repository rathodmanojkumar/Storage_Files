#!/bin/bash

curdt=`date +%d-%m-%Y`
bold_red="\e[1m\e[31m"
bold_green="\e[1m\e[32m"
reset="\e[0m"

log_file="install_script_${curdt}.log"

log() {
    local message="$1"
    local print_to_shell="$2"
    local log_entry="$(date '+%Y-%m-%d %H:%M:%S') - $message"
    echo "$log_entry" >> "$log_file"
    if [ "$print_to_shell" == "true" ]; then
        echo "$log_entry"
    fi
}

tasks=(
    "Install Naps Scanner"
    "Install Only Epson Driver and Epson Scanner"
    "Install Fijustu Scanner Driver"
    "Install other Ubuntu Apps (e.g.-Dictionary)"
    "Install/Update Proxykey for ubuntu"
    "Repair the Anydesk issue"
    "Install Canon LBP 246dw Printer Driver"
)

check_dependency() {
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${bold_red}${cmd}${reset} could not be found, please install it."
            exit 1
        fi
    done
}

confirm() {
    read -p "Are you sure you want to proceed? [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY]) true ;;
        *) false ;;
    esac
}

zip_files() {
    if [ -d "./files" ]; then
        echo "Files already extracted. Using existing files."
    elif [ -f "files.zip" ]; then
        echo "files.zip found but not extracted. Extracting files..."
        unzip -q files.zip
    else
        echo "Downloading offline files.zip..."
        wget -q https://github.com/rathodmanojkumar/Storage_Files/raw/main/files.zip
        echo "Unzipping files.zip..."
        unzip -q files.zip
    fi
}

install_naps() {
    echo "This will Install Naps Scanner"
    if confirm; then
        keyring_path="/etc/apt/keyrings/naps2.gpg"
        if [ ! -f "$keyring_path" ]; then
            curl -fsSL https://www.naps2.com/naps2-public.pgp | sudo gpg --dearmor -o "$keyring_path"
        fi
        if ! grep -q "^deb .*$keyring_path" /etc/apt/sources.list.d/naps2.list 2>/dev/null; then
            echo "deb [signed-by=$keyring_path] https://downloads.naps2.com ./" | sudo tee /etc/apt/sources.list.d/naps2.list >/dev/null
        fi
        sudo apt update
        sudo apt install -y naps2
        log "${bold_green}NAPS2 installation completed${reset}" true
    else
        echo "Installation is Cancelled by user"
    fi        
}

install_epson() {
    echo "This will Install Epson Driver "
    if confirm; then
        sudo apt update
        sudo apt install -y lsb lsb-core
        zip_files
        sudo dpkg -i ./files/epson-inkjet-printer-escpr2_1.2.3-1_amd64.deb
        sudo sh ./files/epsonscan2-bundle-6.7.61.0.x86_64.deb/install.sh
        sudo apt purge ipp-usb -y
        log "${bold_green}The Driver installation Epson is complete.${reset}" true
    else
        log "Installation canceled by user"
    fi
}

install_fijustu() {
    if confirm; then
        zip_files
        sudo dpkg -i ./files/pfufs-ubuntu_2.8.0_amd64.deb
        log "${bold_green}Successfully installed Fujitsu Driver${reset}" true
    else
        echo "Installation canceled by user"
    fi
}

install_apps() {
    echo "In this Installation following apps will be installed:"
    echo -e "Golden_Dictionary\nProxykey\nDolphine File explorer\nClipboard\nNet-tools\nOpenSSH-server"
    if confirm; then
        sudo apt update
        sudo apt install -y diodon goldendict goldendict-wordnet openssh-server net-tools dolphin
        log "${bold_green}Successfully installed apps${reset}" true
    else
        echo "Installation canceled by user"
    fi 
}

install_proxykey() {
    echo "This will install or update Proxykey"
    if confirm; then
        zip_files
        sudo dpkg -i ./files/proxkey_ubantu.deb
        log "${bold_green}Successfully installed proxykey for ubuntu${reset}" true
    else
        echo "Installation canceled by user"
    fi 
}

repair_anydesk() {
    echo -e "${bold_red}This will remove AnyDesk directory. This process doesn't install AnyDesk.${reset}"
    if confirm; then
        sudo rm -rf ~/.anydesk
        log "Successfully repaired AnyDesk" true
    else
        echo "Installation canceled by user"
    fi 
}

install_canon_lbp246dw() {
    echo "This will install Canon LBP 246dw printer driver"
    if confirm; then
        set -e
        DRIVER_URL="https://raw.githubusercontent.com/rathodmanojkumar/Storage_Files/main/linux-UFRII-drv-v610-m17n-03.tar.gz"
        TAR_NAME="linux-UFRII-drv-v610-m17n-03.tar.gz"
        PRINTER_NAME="Canon_LBP246dw"

        UBUNTU_VER=$(lsb_release -rs)
        log "📌 Detected Ubuntu version: $UBUNTU_VER"

        if apt-cache search libjpeg62-turbo | grep -q libjpeg62-turbo; then
            JPEG_PKG="libjpeg62-turbo"
        else
            JPEG_PKG="libjpeg62"
        fi

        if apt-cache search system-config-printer | grep -q '^system-config-printer '; then
            PRINTER_PKG="system-config-printer"
        else
            PRINTER_PKG="system-config-printer-gnome system-config-printer-common"
        fi

        log "📦 Installing required packages: $JPEG_PKG, $PRINTER_PKG ..."
        sudo apt update -y
        sudo apt install -y libcups2 cups printer-driver-gutenprint csh $JPEG_PKG avahi-utils $PRINTER_PKG

        sudo systemctl enable cups
        sudo systemctl start cups

        wget -q --show-progress -O "$TAR_NAME" "$DRIVER_URL"
        tar -xzf "$TAR_NAME" -C "$HOME"

        TARGET_DIR=$(find "$HOME" -maxdepth 1 -type d -name "linux-UFRII-drv-*" | head -n 1)
        if [ -z "$TARGET_DIR" ] || [ ! -f "$TARGET_DIR/install.sh" ]; then
            log "❌ Could not find install.sh in extracted Canon driver folder"
            exit 1
        fi

        chmod 777 "$TARGET_DIR/install.sh"
        ( cd "$TARGET_DIR" && sudo ./install.sh )

        PRINTER_URI=$(lpinfo -v | grep -i 'Canon' | grep -i 'LBP' | head -n 1 | awk '{print $2}')
        if [ -n "$PRINTER_URI" ]; then
            sudo lpadmin -p "$PRINTER_NAME" -E -v "$PRINTER_URI" -m everywhere
            sudo lpoptions -d "$PRINTER_NAME"
            log "✅ Printer '$PRINTER_NAME' installed and set as default"
        else
            log "⚠ No Canon LBP printer detected automatically — add it manually."
        fi

        sudo systemctl restart cups

        if command -v gnome-control-center &> /dev/null; then
            nohup gnome-control-center printers >/dev/null 2>&1 &
        elif command -v system-config-printer &> /dev/null; then
            nohup system-config-printer >/dev/null 2>&1 &
        fi

        log "🎉 Canon driver installation completed! Check Ubuntu Printer Settings to confirm."
    else
        echo "Installation canceled by user"
    fi
}

execute_task() {
    case $1 in
        1) install_naps ;;
        2) install_epson ;;
        3) install_fijustu ;;
        4) install_apps ;;
        5) install_proxykey ;;
        6) repair_anydesk ;;
        7) install_canon_lbp246dw ;;
        *) echo "Invalid entry. Please try again." ;;
    esac
}

check_dependency "curl" "wget" "unzip"

PS3="Select option by number: "
echo -e "${bold_red}This script is applicable for Ubuntu 22.04/20.04 (Dell and HP models)${reset}"
select option in "${tasks[@]}" "exit"
do
    echo -e "\nYou have selected : $option\n"
    if [[ $REPLY -le ${#tasks[@]} ]]; then
        execute_task $REPLY
    elif [[ $REPLY == $(( ${#tasks[@]} + 1 )) ]]; then
        echo "Exiting..."
        break
    else
        echo "Invalid entry. Please try again."
    fi
done
