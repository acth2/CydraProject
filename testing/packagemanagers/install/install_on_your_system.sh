#!/bin/bash

clear
echo "========================================="
echo "1] Installé le gestionnaire de packets   "
echo "2] Déinstallé le gestionnaire de packets"
echo "3] Reinstallé le fichier de configuration [NON AJOUTE]"
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

if [ "$use" == "2" ]
then

        sudo rm -rf /etc/cydramanager

        sudo rm -f /usr/bin/cydramanager
        sudo rm -f /etc/cydramanager.conf
        echo "CydraManagers a été déinstallé avec succés !"
        exit 0
fi

if [ "$use" == "3" ]
then
        echo "Fonctionalité non ajouté pour le moment!"
        exit 0
fi

##############
echo "Commande non trouvé.."
sleep 2
##############
