#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)
PROJECT_DIR="${SCRIPT_DIR}"
UTILS_DIR="${PROJECT_DIR}/utils"
DISTRO=$("${UTILS_DIR}/distro-info")
DISTRO_UTILS_DIR="${UTILS_DIR}/${DISTRO}"

interactiveCfg() {
    DEFAULT_VALUE=$(grep -Po "(?<=^$2=).*" "${PROJECT_DIR}/default.conf" | cut -d "#" -f1 | sed 's/^\s*"\(.*\)"\s*$/\1/' | xargs)
    COMMENT=$(grep -Po "(?<=^$2=).*" "${PROJECT_DIR}/default.conf" | cut -d "#" -f2-)
    #echo "DEFAULT_VALUE: $DEFAULT_VALUE"
    declare -A "$2=$DEFAULT_VALUE"
    TMP_VAR_NAME="TMP_$2";
    #echo "TMP_VAR_NAME: ${TMP_VAR_NAME}"
    read -p "$1 [$DEFAULT_VALUE]: " "$TMP_VAR_NAME";
    declare -A "USER_INPUT=${!TMP_VAR_NAME}"
    #echo "VM_FILES_DIR: ${VM_FILES_DIR}"
    #echo "USER_INPUT: ${!TMP_VAR_NAME}"
    if [ "${USER_INPUT}" != "" ]; then
        FINAL_VALUE="${USER_INPUT}"
    else
        FINAL_VALUE="${DEFAULT_VALUE}"
    fi
    declare -g "$2=${FINAL_VALUE}"
    #echo "FINAL_VALUE: $FINAL_VALUE"
    if [ "${USER_CONFIG_FILE}" != "" ]; then
        crudini --set "${USER_CONFIG_FILE}" "" "$2" "\"${FINAL_VALUE}\" #${COMMENT}"
        echo "> Set $2 to '${FINAL_VALUE}'"
    fi
    # TODO: change modified value on config file USER_CONFIG_FILE
}

echo "!!!!!!"
echo "IF IN DOUBT WITH ANY OF THE FOLLOWING, JUST PRESS ENTER TO USE THE RECOMMENDED/DEFAULT VALUE!"
echo "!!!!!!"
interactiveCfg "Where should the VM files and configuration be saved?" VM_FILES_DIR
echo "> Directory set to '${VM_FILES_DIR}'"

read -p "Where should the config to be generated be saved? (Will overwrite if necessary) [${VM_FILES_DIR}/user.conf]: " USER_CONFIG_FILE
if [ "$USER_CONFIG_FILE" == "" ]; then
    USER_CONFIG_FILE="${VM_FILES_DIR}/user.conf"
fi
eval "USER_CONFIG_FILE=${USER_CONFIG_FILE}"
#echo "USER_CONFIG_FILE=$USER_CONFIG_FILE"
mkdir -p "$(dirname "${USER_CONFIG_FILE}")"
cp "${PROJECT_DIR}/default.conf" "${USER_CONFIG_FILE}"
echo "> Config will be created at ${USER_CONFIG_FILE}'"

interactiveCfg "What should the name of the VM be?" VM_NAME
interactiveCfg "Where to save the VM drive image?" DRIVE_IMG
interactiveCfg "How big should the VM drive image be?" VM_DISK_SIZE
interactiveCfg "How many CPU cores should the VM get?" CPU_CORE_COUNT
interactiveCfg "How much RAM should the VM get?" RAM_SIZE
interactiveCfg "Path to your Windows installation iso. (If it doesn't exist it will be downloaded automatically.)" INSTALL_IMG
interactiveCfg "Path to a dGPU ROM. (Optional)" DGPU_ROM
interactiveCfg "Path to a folder to share with the VM via SMB. (Optional)" SMB_SHARE_FOLDER
interactiveCfg "Location of OVMF_VARS.fd." OVMF_VARS
interactiveCfg "Where to create Creating a copy of OVMF_VARS.fd (containing the executable firmware code and but the non-volatile variable store) for the VM?" WIN_VARS
interactiveCfg "Location of OVMF_CODE.fd." OVMF_CODE
interactiveCfg "Location of the virtio Windows driver disk." VIRTIO_WIN_IMG
interactiveCfg "Location of helper iso or where to create it." HELPER_ISO
interactiveCfg "Pass the dGPU through to the VM." DGPU_PASSTHROUGH
interactiveCfg "Share the iGPU with the VM to allow using Optimus within the VM to save battery life" SHARE_IGPU
interactiveCfg "dGPU driver used by the Linux host (nvidia or nouveau). (nouveau is untested)" HOST_DGPU_DRIVER
interactiveCfg "The PCI address of your dGPU as obtained by 'lspci' or 'optimus lspci'. (01:00.0 unless you don't have Bumblebee)" DGPU_PCI_ADDRESS
interactiveCfg "The PCI address of your iGPU as obtained by 'lspci'. (Usually 00:02.0)" IGPU_PCI_ADDRESS
interactiveCfg "Virtual input device mode for keyboard and mouse. (if usb-tablet doesn't work properly, you may want to switch to virtio)" VIRTUAL_INPUT_TYPE
interactiveCfg "MAC address to use or leave empty to generate a random one" MAC_ADDRESS
if [ "$MAC_ADDRESS" == "" ]; then
    MAC_ADDRESS=$(printf '52:54:BE:EF:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256)))
    echo "> MAC_ADDRESS generated: ${MAC_ADDRESS}"
    echo "> Set MAC_ADDRESS to '${MAC_ADDRESS}'"
    crudini --set "${USER_CONFIG_FILE}" "" "MAC_ADDRESS" "\"${MAC_ADDRESS}\""
fi
interactiveCfg "Network mode to use? Only supports TAP at the moment." NETWORK_MODE
interactiveCfg "Use Looking Glass to get super low latency video output." USE_LOOKING_GLASS
interactiveCfg "Max screen width with Looking Glass." LOOKING_GLASS_MAX_SCREEN_WIDTH
interactiveCfg "Max screen height with Looking Glass." LOOKING_GLASS_MAX_SCREEN_HEIGHT
interactiveCfg "Version of Looking Glass to use (a12 is highly recommended)" LOOKING_GLASS_VERSION
interactiveCfg "Enable spice. (Recommended for Looking Glass, required to install Windows)" USE_SPICE
interactiveCfg "Port to use for spice." SPICE_PORT
interactiveCfg "Enable dma-buf. (Yet another way to get display access to your VM)" USE_DMA_BUF
interactiveCfg "Enable QXL. (Required for Windows installation; has to be disabled after the Nvidia driver has been installed!)" USE_QXL
interactiveCfg "List of USB devices to pass through. (Semicolon separated, e.g. vendorid=0x0b12,productid=0x9348;vendorid=0x0b95,productid=0x1790)" USB_DEVICES
# TODO: Make selecting USB devices easier

source "$USER_CONFIG_FILE"
if [ ! -f "$INSTALL_IMG" ]; then
    echo "'$INSTALL_IMG' does not exist and will be downloaded automatically now. If you don't want that, press Ctrl+C to cancel it."
    $UTILS_DIR/download-windows-iso "$INSTALL_IMG"
fi
