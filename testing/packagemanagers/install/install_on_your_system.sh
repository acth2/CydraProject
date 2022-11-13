#!/bin/bash

clear
echo "========================================="
echo "1] Installé le gestionnaire de packets   "
echo "2] Déinstallé le gestionnaire de packets [NOT NOW] "
echo "3] Réparé le gestionnaire de packets     [NOT NOW]"
echo "4] Reinstallé le fichier de configuration[NOT NOW]"
echo "========================================="

read use

if [ "$use" == "1" ]
then

	sudo mkdir /etc/cydramanager

	sudo cp -r ../software/cydramanager /usr/bin
	sudo cp -r ../software/data/etc/* /etc
	echo "CydraManagers a été installé avec succés !"
	exit 0
fi


##############
echo "Commande non trouvé.."
sleep 2
##############
