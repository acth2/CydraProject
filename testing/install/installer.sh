#!/bin/env bash


BOLD_WHITE="\e[1;37m"
BOLD_BLUE="\e[1;34m"
BOLD_PURPLE="\e[1;35m"
RESET_COLOR="\e[0m"

#			VARS			#

IS_EFI=1
OLD_PASSWORD=""
ISO_NAME="install_os.iso"
ISO_PATH="/etc/${ISO_NAME}"
declare -A AVAILIBLE_LANGUAGES=(
	[1]=en-US
	[2]=fr-FR
)


log() {
	echo -e "[${BOLD_BLUE}LOG${RESET_COLOR}] $*"
}

section() {
	echo -e "[${BOLD_PURPLE}${1}${RESET_COLOR}] Entering '${BOLD_WHITE}${1}${RESET_COLOR}' process"
}

# - - - - - - - - - - - - - #







#		INFORMATIONS		#

function welcome_menu {
	log "Welcome menu"
	dialog --msgbox "Welcome into CydraProject (Lite) installation guide!" 15 50
}

function print_licences {
	log "Showing licenses"
	dialog --msgbox "Licenses on: https://github.com/acth2/CydraProject/blob/main/LICENSE" 15 50
}


function print_credits {
	log "Showing credits"
	dialog --msgbox "Thanks to AinTea for the installer !\n Here the github of AinTea: https://github.com/AinTEAsports\n Here the github of CydraProject: https://github.com/acth2/CydraProject" 15 50
}


function INFORMATIONS {
	section "INFORMATIONS"

	welcome_menu
	print_licences
	print_credits
}


# - - - - - - - - - - - - - #


function get_password {
	log "Getting password"
	password="$(dialog --insecure --passwordbox "Enter new password:" 0 0 --stdout)"

	# Set new root password
	log "Setting password..."
	[[ -n "${password}" ]] || echo -e "${OLD_PASSWORD}\n{password}\n{password}" | passwd
	log "Password set"
}


function get_language {
	log "Getting language"

	language=$(dialog --radiolist "Select system language:" 0 0 0 \
		1 "en-US" on \
		2 "fr-FR" off \
		--stdout
	)

	case "${language}" in
		"en-US") export LANG="en_US.UTF-8";;
		"fr-FR") export LANG="fr_FR.UTF-8";;
		*) ;;
	esac

	log "Language set to '${language}'"
}


function get_machine_name {
	log "Getting machine name"
	machine_name="$(dialog --title "Dialog title" --inputbox "Enter machine name:" 0 0 --stdout)"

	# Set machine name to 'machine_name'
	log "Setting machine name..."
	sudo hostname "${machine_name}"
	log "Machine name set"
}


function configure_network {
	log "Configuring network"

	log "Getting network name and password"
	network_name="$(dialog --title "Dialog title" --inputbox "Enter network name:" 0 0 --stdout)"
	network_password="$(dialog --insecure --passwordbox "Enter network password:" 0 0 --stdout)"

	# Activating wireless interface
	log "Activating wireless interface"
	sudo ifconfig wlp3s0 up
	sudo wpa_passphrase WLAN_NAME WLAN_PASSWORD > /etc/wpa_supplicant.conf

	log "Connecting to network"
	wpa_supplicant -B -i wlp3s0 -c /etc/wpa_supplicant.conf -D wext
	sudo dhclient wlp3s0
	log "Connected to network"
}


function GET_USER_INFOS {
	section "GET USER INFOS"

	get_username
	get_password
	get_language
	get_machine_name
	configure_network

	echo -e "\n"
}


# - - - - - - - - - - - - - #




#		DISK PARTITION		#

function DISK_PARTITION {
	section "DISK PARTITIONNING"

	chosen_partition="$(dialog --title "Dialog title" --inputbox "Enter chosen partition on which will be installed system, \n Exemple: /dev/sdb or /dev/sda3" 20 60 --stdout)"
    dialog --title "Swap partition" \
    --backtitle "Do you want a swap?" \
    --yesno "Do you want to use a swap? If yes, please give us the name of the partition/disk where we can install it! \n( 2GO will be enough" 20 60
        response=$?
        case $response in
             0) 	chosen_swap="$(dialog --title "Dialog title" --inputbox "Enter chosen partition on which will be installed the swap, \n Exemple: /dev/sda1 or /dev/sdb2" 20 60 --stdout)";;
	    esac
    if [ -d /sys/firmware/efi ]; then
        dialog --title "Efi detected" --msgbox "EFI was been detected ! \n CydraLite will be in EFI \n\n But if you dont want disable it on the BIOS CydraLite will boot anyway"
        IS_EFI = 0
    fi
}

function DISK_INSTALL {
    section "INSTALL DISK"

    mkfs.ext4 ${chosen_partition}
    
}

#		GRUB CONFIGURATION		#

function GRUB_CONF {
    section "GRUB CONFIGURING"


    if [ IS_EFI = 1 ]; then
        grub-install ${chosen_partition}
    else
        grub-install --target=x86_64-efi --removable
    fi
    rm -rf /mnt/install/boot/grub/grub.cfg
    grub-mkconfig –o /mnt/install/boot/grub/grub.cfg 

}

#		CYDRA INSTALLATION		#

function INSTALL_CYDRA {
    section "INSTALLING CYDRA"

    mkdir /mnt/install
    mount ${chosen_partition} /mnt/install
    cp -r /* /mnt/install > /dev/null 2>&1;
    wget -P /mnt/install/etc/rc.d/rcS.d/ https://raw.githubusercontent.com/acth2/CydraProject/main/osfile/S20swap > /dev/null 2>&1;
    wget -P /mnt/install/etc/rc.d/rcS.d/ https://raw.githubusercontent.com/acth2/CydraProject/main/osfile/S40mountfs > /dev/null 2>&1;
}

#		INIT SWAP		#

function INIT_SWAP {
    mkswap ${chosen_swap}
}

#		CLEAN UP		#

function CLEAN_LIVE {
    section "CLEANING LIVECD BEFORE REBOOTING"

    umount /mnt/install
}


# - - - - - - - - - - - - - #



function main {
	section "INSTALLATION"
	INFORMATIONS
	GET_USER_INFOS
	DISK_PARTITION


	# If the user wants to continue the installation or return to the beginning
	if dialog --yesno "Installation is finished, do you want to continue ?" 0 0 --stdout; then

		# If any field was left blank
		if [[ -z "${username}" || -z "${password}" || -z "${language}" || -z "${machine_name}" || -z "${network_name}" || -z "${network_password}" ]]; then
			main "$@"
		else
       		log "installation on '${chosen_partition}'"
            dialog --msgbox "!! WARNING !! \n\n EVERY DATA ON THE DISK WILL BE ERASED" 15 50
            DISK_INSTALL
            INSTALL_CYDRA
            INIT_SWAP
			GRUB_CONF
			CLEAN_LIVE

			dialog --msgbox "Installation is finished, thanks for using CydraOS !" 0 0
			exit 0
		fi
	else
		main "$@"
	fi
}

main "$@"
