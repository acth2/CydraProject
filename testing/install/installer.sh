#!/bin/bash


BOLD_WHITE="\e[1;37m"
BOLD_BLUE="\e[1;34m"
BOLD_PURPLE="\e[1;35m"
RESET_COLOR="\e[0m"

#			VARS			#

IS_EFI=1
SWAPUSED=0
CORRECTDISK=0
OLD_PASSWORD=""
partition_list=($(lsblk -nr -o NAME,TYPE | awk '$2 == "disk" {print "/dev/" $1}'));
WIRELESS=0

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
	password="$(dialog --insecure --passwordbox "Enter machine password:" 0 0 --stdout)"

	# Set new root password
	log "Setting password..."
	[[ -n "${password}" ]] || echo -e "${OLD_PASSWORD}\n{password}\n{password}" | passwd
	log "Password set"
}


function get_language {
	log "Getting language"

	language="$(dialog --title "Dialog title" --inputbox "Enter language name (fr / us):" 0 0 --stdout)"
        if [[ -n "${language}" ]]; then
	    loadkeys "${language}"
            log "Language set to '${language}'"
        else
            log "Empty output, US by default.."
	    sleep 2
        fi

}

function get_informations {
	log "Getting machine name"
	machine_name="$(dialog --title "System informations" --inputbox "Enter machine name:" 0 0 --stdout)"
        username="$(dialog --title "System informations" --inputbox "Enter your username:" 0 0 --stdout)"
        password="$(dialog --title "System informations" --insecure --passwordbox "Enter machine password" 0 0 --stdout)"
}


function configure_network {
	if dialog --yesno "Does the system should use Wireless connection?" 0 0 --stdout; then
            WIRELESS=1
	    log "Configuring network"

	    log "Getting network name and password"
	    network_name="$(dialog --title "Network name" --inputbox "Enter network name:" 0 0 --stdout)"
	    network_password="$(dialog --title "Network password" --insecure --passwordbox "Enter network password:" 0 0 --stdout)"

	    log "Configuration of the network."

	    sudo ifconfig wlp3s0 up
	    sudo wpa_passphrase WLAN_NAME WLAN_PASSWORD > /etc/wpa_supplicant.conf

	    log "Configuration to network"
	    wpa_supplicant -B -i wlp3s0 -c /etc/wpa_supplicant.conf -D wext
     	    mkdir "/root/installdir"
            mv "/etc/unusedwireless" "/root/installdir/25-wireless.network"
	    log "Network configured"
            sleep 2
        else
            rm -f "/etc/unusedwirless"
	    log "Network configured"
            sleep 2
        fi
}


function GET_USER_INFOS {
	section "GET USER INFOS"

	get_language
	get_informations
	configure_network

	echo -e "\n"
}


# - - - - - - - - - - - - - #




#		DISK PARTITION		#

function DISK_PARTITION {
        clear
        section "DISK PARTITIONNING"
        log "Enter your system partition \nhere the list of your partitions: ${partition_list[@]}"
        echo -n "Input: "
        read chosen_partition
        for item in "${partition_list[@]}"; do
            if [[ "$item" == "${chosen_partition}" ]]; then
                CORRECTDISK=1
                break
            fi
        done
    
        if [[ ${CORRECTDISK} == 0 ]]; then
            log "Error: System disk not found.."
	    sleep 2
            DISK_PARTITION
        fi
	
        if dialog --yesno "Do you want to create a swap partition?" 25 85 --stdout; then
            for i in "${!partition_list[@]}"; do
                if [ "${partition_list[i]}" = "${chosen_partition}" ]; then
                   unset 'partition_list[i]'
                   break
                fi
            done
	    clear
	    log "Enter your swap partition \nhere the list of your partitions: ${partition_list[@]}"
    	    echo -n "Input: "
   	    read swap_partition
	    for item in "${partition_list[@]}"; do
    		if [[ "$item" == "${swap_partition}" ]]; then
                      SWAPUSED=1
                      break
                fi
            done
	    if [[ ${SWAPUSED} == 0 ]]; then
                log "Error: The SWAP will not be used.. Bad values"
            fi
        fi
    
        if [ -d /sys/firmware/efi ]; then
	    if dialog --title "Efi detected"  --yesno "EFI was been detected ! Do you want to create an EFI partition ?" 25 85 --stdout; then
                for i in "${!partition_list[@]}"; do
                    if [ "${partition_list[i]}" = "${swap_partition}" ]; then
                        unset 'partition_list[i]'
                        break
                    fi
                done
		clear
	        log "Enter your EFI partition \nhere the list of your partitions: ${partition_list[@]}"
    	        echo -n "Input: "
   	        read efi_partition
		efi_partition_size_kb=$(df -k --output=size "${efi_partition}" | tail -n 1)
    	   	efi_partition_size_gb=$((efi_chosen_partition_size_kb / 1048576))
		for item in "${partition_list[@]}"; do
    		    if [[ "$item" == "${efi_partition}" ]]; then
                        IS_EFI=0
			if [ "3" -ge "${efi_partition_size_gb}" ]; then
                            IS_EFI=2
                        fi
                        break
                    fi
                done
	        if [[ ${IS_EFI} == 2 ]]; then
                    log "Error: EFI will not be used.. Not enough space"
                fi
		
		if [[ ${IS_EFI} == 1 ]]; then
                   log "Error: EFI will not be used.. Bad values"
                fi
            fi
        fi
}

function DISK_INSTALL {
    section "INSTALL DISK"
    mkdir -p "/mnt/install"
    mkdir -p "/mnt/efi"
    mkdir -p "/mnt/temp"
    mkfs.ext4 -F ${chosen_partition}
}

#		GRUB CONFIGURATION		#

function GRUB_CONF {
    section "GRUB CONFIGURING"


    if [ IS_EFI = 1 ]; then
        mainPartitionUuid=$(blkid ${chosen_partion})
	if [ SWAPUSED = 0 ]; then
	    swapPartitionUuid=$(blkid ${swap_partion})
        fi
	mount -t ext4 ${chosen_partition} "/mnt/install"
        mkdir -p /mnt/install/boot
        grub-install --root-directory=/mnt/install/boot ${chosen_partition}
    else
        mainPartitionUuid=$(blkid ${chosen_partion})
	if [ SWAPUSED = 0 ]; then
	    swapPartitionUuid=$(blkid ${swap_partion})
        fi
        efiPartitionUuid=$(blkid ${efi_partion})
	mkdir /mnt/efi
	if [[ "$efi_partition" =~ [0-9]$ ]]; then
  	     efi_device=$(echo "$efi_partition" | sed 's/[0-9]*$//')
  	     (
  	     echo "d"        
             echo "n"   
             echo "p"   
             echo "1"   
             echo       
             echo    
             echo "w" 
             ) | fdisk "${efi_device}"
  	     log "The partition ${efi_partition} has been set to EFI System Partition."

	else
              (
              echo "n"   
              echo "p"   
              echo "1"   
              echo       
              echo    
              echo "w"
              ) | fdisk "${efi_partition}"
 	      log "An EFI partition has been created on the device ${efi_partition}."
	fi
        mkfs.vfat -F 32 "${efi_partition}1"
	mkdir /mnt/efi
 	mount "${efi_partition}1" "/mnt/efi"
	log "The partition ${efi_partition}1 has been formatted as FAT32."
        grub-install "${efi_partition}1" --root-directory=/mnt/efi --target=x86_64-efi --removable
	rm -f "/mnt/efi/boot/grub/grub.cfg"
    fi
    rm -rf "/mnt/install/boot/grub/grub.cfg"
    rm -rf "/mnt/efi/boot/grub/grub.cf"
    touch "/mnt/efi/boot/grub/grub.cfg"
    local disk=$(echo ${chosen_partition} | sed -E 's|/dev/([a-z]+)[0-9]*|\1|')
    local partition_letter=$(echo ${chosen_partition} | grep -o '[0-9]*$')
    local disk_letter=${disk:2:1}
    local grub_disk_letter=$(( $(printf "%d" "'${disk_letter}") - $(printf "%d" "'a") ))
    echo "set default=0" >> "/mnt/efi/boot/grub/grub.cfg"
    echo "set timeout=5" >> "/mnt/efi/boot/grub/grub.cfg"
    echo "" >> "/mnt/efi/boot/grub/grub.cfg"
    echo "insmod part_gpt" >> "/mnt/efi/boot/grub/grub.cfg"
    echo "insmod ext2" >> "/mnt/efi/boot/grub/grub.cfg"
    echo "set root=(hd${grub_disk_letter},${partition_letter})" >> "/mnt/efi/boot/grub/grub.cfg"
    echo "insmod all_video" >> "/mnt/efi/boot/grub/grub.cfg"
    echo "if loadfont /boot/grub/fonts/unicode.pf2; then" >> "/mnt/efi/boot/grub/grub.cfg"
    echo "  terminal_output gfxterm" >> "/mnt/efi/boot/grub/grub.cfg"
    echo "fi" >> "/mnt/efi/boot/grub/grub.cfg"
    echo "" >> "/mnt/efi/boot/grub/grub.cfg"
    echo 'menuentry "GNU/Linux, CydraLite Release V2.0"  {' >> "/mnt/efi/boot/grub/grub.cfg"
    echo "  search --no-floppy --fs-uuid --set=root ${chosen_partition}" >> "/mnt/efi/boot/grub/grub.cfg"
    echo "  linux /boot/os root=UUID=${chosen_partition} ro quiet" >> "/mnt/efi/boot/grub/grub.cfg"
    echo "}" >> "/mnt/efi/boot/grub/grub.cfg"
    echo "" >> "/mnt/efi/boot/grub/grub.cfg"
    echo "menuentry "Firmware Setup" {" >> "/mnt/efi/boot/grub/grub.cfg"
    echo "  fwsetup" >> "/mnt/efi/boot/grub/grub.cfg"
    echo "}" >> "/mnt/efi/boot/grub/grub.cfg"
}

#		CYDRA INSTALLATION		#

function INSTALL_CYDRA {
    section "INSTALLING CYDRA"

    mkdir "/mnt/install"
    mount -t ext4 ${chosen_partition} "/mnt/install"
    unsquashfs -f -d "/mnt/install" "/usr/bin/system.sfs"
    cp -r "/mnt/temp/*" "/mnt/install"
    rm -f "/mnt/install/etc/fstab"
    touch "/mnt/install/etc/fstab"
    echo "#CydraLite FSTAB File, Make a backup if you want to modify it.." >> /mnt/install/etc/fstab
    echo "" >> /mnt/install/etc/fstab
    echo "UUID=${mainPartitionUuid}     /            ext4    defaults            1     1" >> /mnt/install/etc/fstab
    if [ SWAPUSED = 0 ]; then
	echo "UUID=${swapPartitionUuid}     swap         swap     pri=1               0     0" >> /mnt/install/etc/fstab
    fi
    
    if [ IS_EFI = 0 ]; then
	echo "UUID=${efiPartitionUuid} /boot/efi vfat codepage=437,iocharset=iso8859-1 0 1" >> /mnt/install/etc/fstab
    fi
    
    if [[ ${WIRELESS} = 1 ]]; then
	mv "/root/installdir/25-wireless.network" "/mnt/install/systemd/network/25-wireless.network"
    fi
    rm -f "/mnt/install/etc/wpa_supplicant.conf"
    cp -r "/etc/wpa_supplicant.conf" "/mnt/install/etc/wpa_supplicant.conf"
    
}

#		INIT SWAP		#

function INIT_SWAP {
    mkswap -f "${chosen_swap}"
}

#		CLEAN UP		#

function CLEAN_LIVE {
    section "CLEANING LIVECD BEFORE REBOOTING"

    umount "/mnt/install" > /dev/null 2>&1;
    umount "/mnt/efi" > /dev/null 2>&1;
    umount "/mnt/temp" > /dev/null 2>&1;
}


# - - - - - - - - - - - - - #



function main {
	section "INSTALLATION"
	INFORMATIONS
	GET_USER_INFOS
	DISK_PARTITION


	if dialog --yesno "The Installation will start. Continue?" 25 85 --stdout; then

		if [[ -z "${password}" || -z "${username}" || -z "${machine_name}" || -z "${chosen_partition}" ]]; then
			err  "$@"
                        /usr/bin/install
		elif [[ ${WIRELESS} = 1 ]]; then
                     if [[ -z "${network_name}" || -z "${network_password}" ]]; then
        		     err  "$@"
                             /usr/bin/install
                     fi	
                else
       			log "installation on '${chosen_partition}'"
	                if dialog --yesno "!! WARNING !! \n\nEVERY DATA ON THE DISK WILL BE ERASED.\nDo you want to continue ?" 25 85 --stdout; then
		             mkdir -p ""
            		     DISK_INSTALL
		   	     GRUB_CONF
            		     INSTALL_CYDRA
            		     INIT_SWAP
	    		     CLEAN_LIVE

	     		     dialog --msgbox "Installation is finished, thanks for using CydraOS !" 0 0
	                else
  			     if dialog --yesno "Do you want to exit the Installation ?" 15 35 --stdout; then
	                          stty -echo
	                          export PS1="Exiting system..."
			          clear
			          halt
                             else
			          log "Cleaning the vars.."
	                          sleep 1
	                          unset "IS_EFI"
			          unset "SWAPUSED"
	                          unset "CORRECTDISK"
			          unset "OLD_PASSWORD"
	                          unset "partition_list"
			          unset "WIRELESS"
	                          unset "AVAILIBLE_LANGUAGES"
			          log "vars cleaned, restarting installation.."
			          sleep 2
                                  /usr/bin/install
	                     fi
                        fi
			exit 0
		fi
	else
		main "$@"
	fi
}

function err {
	dialog --msgbox "The installation failed. The user did not gived all of the needed informations for the installation." 15 100
}

main "$@"
