#!/bin/env bash


#			VARS			#

declare -A AVAILIBLE_LANGUAGES=(
	[1]=en-US
	[2]=fr-FR
)

# - - - - - - - - - - - - - #







#		INFORMATIONS		#

function welcome_menu {
	dialog --msgbox "Welcome menu"
}

function print_licences {
	dialog --msgbox "Licenses here"
}


function print_credits {
	echo "Credits"
}


# Rename this
function INFORMATIONS {
	echo -e "--| INFORMATIONS |--\n"

	welcome_menu
	print_licences
	print_credits

	echo -e "--------------------\n"
}

# - - - - - - - - - - - - - #






#		GET USER INFOS		#

function get_username {
	echo "Get username"
	username="$(dialog --title "Dialog title" --inputbox "Enter system username:" 0 0 --stdout)"
}


function get_password {
	echo "Get password"

	if [[ -n "${username}" ]]; then
		password="$(dialog --insecure --passwordbox "Enter '${username}' password:" 0 0 --stdout)"
	else
		password="$(dialog --insecure --passwordbox "Enter user password:" 0 0 --stdout)"
	fi
}


function get_language {
	echo "Get language"

	language=$(dialog --radiolist "Select system language:" 0 0 0 \
	1 "en-US" on \
	2 "fr-FR" off \
	--stdout
	)
}


function get_machine_name {
	echo "Get machine name"

	machine_name="$(dialog --title "Dialog title" --inputbox "Enter machine name:" 0 0 --stdout)"
}


function configure_network {
	echo "Configure network"

	network_name="$(dialog --title "Dialog title" --inputbox "Enter network name:" 0 0 --stdout)"
	network_password="$(dialog --insecure --passwordbox "Enter network password:" 0 0 --stdout)"
}


# Rename this
function GET_USER_INFOS {
	echo -e "\n--| GET_USER_INFOS |--\n"

	get_username
	get_password
	get_language
	get_machine_name
	configure_network

	echo "
	Username: ${username}
	Password: ${password}
	Language: ${AVAILIBLE_LANGUAGES[language]}
	Machine name: ${machine_name}
	Network name: ${network_name}
	Network password: ${network_password}
	"

	echo -e "----------------------\n"
}


# - - - - - - - - - - - - - #




#		DISK PARTITION		#

# Rename this
function DISK_PARTITION {
	echo -e "\n--| DISK PARTITION (not complete) |--\n"
	echo -e "------------------------------------\n"
}

# - - - - - - - - - - - - - #



function main {
	INFORMATIONS
	GET_USER_INFOS
	DISK_PARTITION


	# If the user wants to continue the installation or return to the beginning
	if dialog --yesno "Installation is finished, do you want to continue ?" 0 0 --stdout; then

		# If any field was left blank
		if [[ -z "${username}" || -z "${password}" || -z "${language}" || -z "${machine_name}" || -z "${network_name}" || -z "${network_password}" ]]; then
			main "$@"
		else
			dialog --msgbox "Installation is finished, thanks for using CydraOS !" 0 0
		fi
	else
		main "$@"
	fi
}

main "$@"
