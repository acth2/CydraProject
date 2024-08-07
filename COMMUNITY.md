Outils:

CydraProject

Installer : Installation de cydralite
Merci a AinTEA pour sa contribution [https://github.com/AinTEAsports]


cydramanager : Un gestionnaire de packet pour cydraproject
pour plus d'informations utilisez la commande "sudo cydramanager help"
pour installé le gestionnaire de packet, vous pouvez accédé a l'installeur
(ATTENTION: c'est une version beta qui n'est pas terminé et qui peux généré des erreurs )

Packets nouvellement installés: 

make-ca-1.10
CrackLib-2.9.7
cryptsetup-2.4.3
Cyrus SASL-2.1.28
GnuPG-2.3.7
Jansson-2.14
pciutils-3.12.0
libndp-1.8
libxslt
GLib-2.76.4 
docbook
cydramanager 2.0B
cert-ssl
Which-2.21
pciutils-3.7.0
wpa_supplicant
core
libnl
squashfs-tools
Mise+Internet
mandoc-1.14.6
efivar-39
popt-1.19
efibootmgr-18
freetype-2.13.2
grub-2.12 

Le disque dur de mon pc perso a été corrompu, j'ai du donc faire un bon vieux mkfs pour remettre le tout en ordre ce qui ma obligé de donc refaire une installation complete de manjaro linux sa va retardé le développement de l'os d'un jour le temps que je conf virtualbox re mette une sauvegarde que j'avais faite de ma vm contenant l'os ( ouf ) et surtout ! installé firefox je pense bien que c'est l'étape la plus éprouvante a laquel je vais avoir a faire malheureusement ...

FIX /\

Ma VM qui contient l'os n'a pas assez d'espace disque et pour des raisons diverses elle refuse de m'écouté et ne veux pas augmenté son stockage je vais donc me concentré sur l'installeur et le mettre sur une autre vm avec une bonne config et pouvoir continué le dev !

L'installeur avance tres bien ! Le contenu de l'iso sera sur le github a l'exception des font grub et du fichier .sfs de l'os pour des raisons évidentes de places.

Toutes les modifications sur l'iso que j'ai fait depuis 10 jours sont portés sur github

Mon pc est re broken ...
RE: Je ne sais pas si je vais pouvoir bossé sur l'os aujourd'hui puisse que mon virtualbox ne veux tjr par marché ...


L'installeur méttaient des logs d'erreurs tres vites j'ai du donc utilisé obs record l'installation apres reboot grub n'est plus détecté et je boot sur mon bios.. je dois donc utilisé une clé usb pour détecté les fichiers efi et démarré dessus .... oui bien goofy je sais mais quoi qu'il en sois le dev recommence réellement bruh

L'installeur fonctionne en UEFI mais je dois re construire un nouveau .sfs qui contient l'os car celui présent n'a pas vraiment l'air de fonctionné..

RIP mon ordinateur j'en vais marre je l'ai transformé en serveur...

J'ai bientot fini l'installeur mais je me frappe a un mur je trouve pas de solution a mon erreur ..
