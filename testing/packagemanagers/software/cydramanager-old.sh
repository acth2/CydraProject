#!/bin/bash
# shellcheck disable=SC2034
# shellcheck disable=SC2016
# shellcheck disable=SC2140
# shellcheck disable=SC2128
# shellcheck disable=SC2157
# shellcheck disable=SC2049

rm -rf "/etc/cydraterms/tempVerFile" 2> /dev/null
wget "https://raw.githubusercontent.com/acth2/CydraProject/main/packagemanager/version" -P "/etc/cydraterms/tempVerFile" --no-check-certificate -q

CURRENT_GDP_VERSION=$(cat /etc/cydraterms/tempVerFile/version)
GDP_VERSION="1.951 Beta"
MIRROR_URL=$(cat /etc/cydrafetch/currentMirror)
PM_URL=$(cat /etc/cydraterms/mainserver.list/mainserver.list)
CORE_BRANCH="core"
MULTILIB_BRANCH="multilib"
EXTRA_BRANCH="extra"
POOL_BRANCH="pool"
CYDRA_BRANCH="cydra"
CACHE_FILE="/etc/cydramanager/cache"
INSTALL_DIR="/etc/cydramanager/installdir/"
FETCH_DIR="/etc/cydrafetch/"
CORE_DL_URL="${MIRROR_URL}/${CORE_BRANCH}/os/x86_64/${CORE_BRANCH}.db.tar.gz"
MULTILIB_DL_URL="${MIRROR_URL}/${MULTILIB_BRANCH}/os/x86_64/${MULTILIB_BRANCH}.db.tar.gz"
EXTRA_DL_URL="${MIRROR_URL}/${EXTRA_BRANCH}/os/x86_64/${EXTRA_BRANCH}.db.tar.gz"
CYDRA_DL_URL="${PM_URL}/pm/${CYDRA_BRANCH}/${CYDRA_BRANCH}.tar.gz"
CORE_FILES_DL_URL="${MIRROR_URL}/${CORE_BRANCH}/os/x86_64/${CORE_BRANCH}.files.tar.gz"
MULTILIB_FILES_DL_URL="${MIRROR_URL}/${MULTILIB_BRANCH}/os/x86_64/${MULTILIB_BRANCH}.files.tar.gz"
EXTRA_FILES_DL_URL="${MIRROR_URL}/${EXTRA_BRANCH}/os/x86_64/${EXTRA_BRANCH}.files.tar.gz"
CORE_DL="${MIRROR_URL}/${CORE_BRANCH}/os/x86_64"
MULTILIB_DL="${MIRROR_URL}/${MULTILIB_BRANCH}/os/x86_64"
EXTRA_DL="${MIRROR_URL}/${EXTRA_BRANCH}/os/x86_64"
POOL_DL="${MIRROR_URL}/${POOL_BRANCH}/packages"
CYDRA_DL="${PM_URL}/pm/${CYDRA_BRANCH}"
DEPS_FILE="${CACHE_FILE}/depsfile.list"
DEPS_FILE="${CACHE_FILE}/modulabledepsfile.list"
PKG_INFO_ARG="desc"
INSTALLED_SOFTWARE_DIR="/etc/cydraterms/installedsoftware"
USER_INSTALLED_SOFTWARE_DIR="/etc/cydraterms/usersoftware"
CHANGELOG="/etc/cydraterms/changelogs.log"

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m'

PRINT_LOG=true
REGISTER_VAR=true
SHOW_HELP=false
PRINT_MIRROR=false
VERBOSE=false
WASH_CACHE=true
INSTALL_PACMAN=false
UPDATE_DB=true
ADD_AS_DEPS=false
VERBOSE=false
PACKAGE="$2"
PAGE="$2"

for arg in "$@"; do
  case "$arg" in
    --without-printing-log)
      PRINT_LOG=false
      ;;
    --print-mirror)
      PRINT_MIRROR=true
      ;;
    -h | -help | --help)
      SHOW_HELP=true
      ;;
    --without-washing-cache)
      WASH_CACHE=false
      ;;
    --install-pacman-while-update)
      INSTALL_PACMAN=true
      ;;
    --without-updating-db)
      UPDATE_DB=false
      ;;
    --add-as-depends)
      ADD_AS_DEPS=true
      ;;
    --filter-result)
      FILTER_RESULT=true
      ;;
    --verbose | --debug)
      VERBOSE=true
      set -x
      ;;
  esac
done

if [[ $EUID -ne 0 ]]; then
   if [ "$PRINT_LOG" = true ]; then
    echo -e "${RED}Ce script doit etre exécuté avec les privilèges root${NC}"
    exit 13
   fi
fi

function open_help {
      if [ -z "${PAGE}" ] || [ "${PAGE}" == 0 ]; then
          echo "Cydramanager - Gestionnaire de paquets simple pour CydraOS"
          echo "Utilisation: cydramanager [install/remove/...] [nom_du_paquet] [arguments]"
          echo
          echo "Options:                                                   Arguments:"
          echo "  install              Installe le paquet specifier         --without-printing-log              Le gdp n'envoira aucun message               "
          echo "  remove               Supprime le paquet specifier         --without-registering-var           Le gdp n'utiliseras aucune variables         "
          echo "  update               Met a jour tout les packets          --print-mirror                      Permet d'affiche le mirror utilisée          "
          echo "  fetch                Permet de changer de mirror          --without-washing-cache             Le gdp ne supprimeras pas le cachee          "
          echo "  version              Affiche la version du gdp            --install-pacman-while-update       Le gdp installera pacman durant la maj       "
          echo "  patchnote            Affiche les nouveautés du gdp        --without-updating-db               Le gdp ne metteras pas a jour les db local   "
          echo "  help                 Affiche ce message d'aide            -h / --help / -help                 Permet d'affiché ce message d'aide           "
          echo
          echo -e "--------------------- ${ORANGE}[PAGE 0 - 1]${NC}"
      exit 0
      elif [ "${PACKAGE}" == 1 ]; then
          echo "Cydramanager - Gestionnaire de paquets simple pour CydraOS"
          echo "Utilisation: cydramanager [install/remove/...] [nom_du_paquet] [arguments]"
          echo
          echo "Options:                                                       Arguments:"
          echo "  changever            Permet de changé la version d'un packet   --add-as-depends Le gdp interpretera le packet comme étant une dependance"
          echo "                                                                 --verbose        Le programme montrera ce qui se passe en arriere plan"
          echo
          echo -e "--------------------- ${ORANGE}[PAGE 0 - 1]${NC}"
          exit 0
      else
          echo -e "${RED}La page ${PAGE} n'existe pas pour le moment.${NC}"
          exit 1
      fi
}

function update_db {
     if [ "$PRINT_LOG" = true ]; then
         echo -e "${GREEN}Mise a jour de la base de donnée des paquets.${NC}"
     fi
     if [ "$UPDATE_DB" = true ]; then
        wget "${CORE_DL_URL}" -P ${CACHE_FILE} --no-check-certificate -q
        wget "${MULTILIB_DL_URL}" -P ${CACHE_FILE} --no-check-certificate -q
        wget "${EXTRA_DL_URL}" -P ${CACHE_FILE} --no-check-certificate -q
        wget "${CYDRA_DL_URL}" -P ${CACHE_FILE} --no-check-certificate -q

        tar xf ${CACHE_FILE}/core.db.tar.gz -C ${CACHE_FILE} > /dev/null 2>&1;
        tar xf ${CACHE_FILE}/multilib.db.tar.gz -C ${CACHE_FILE} > /dev/null 2>&1;
        tar xf ${CACHE_FILE}/extra.db.tar.gz -C ${CACHE_FILE} > /dev/null 2>&1;
        tar xf ${CACHE_FILE}/cydra.tar.gz -C ${CACHE_FILE} > /dev/null 2>&1;

        touch "${DEPS_FILE}"
     fi

     if [ "$PRINT_LOG" = true ]; then
         echo -e "${GREEN}La base de donnée des paquets a ete mise a jour.${NC}"
     fi
}

function update_db_files {
     if [ "$UPDATE_DB" = true ]; then
        wget "${CORE_FILES_DL_URL}" -P ${CACHE_FILE} --no-check-certificate -q
        wget "${MULTILIB_FILES_DL_URL}" -P ${CACHE_FILE} --no-check-certificate -q
        wget "${EXTRA_FILES_DL_URL}" -P ${CACHE_FILE} --no-check-certificate -q
        wget "${CYDRA_FILES_DL_URL}" -P ${CACHE_FILE} --no-check-certificate -q

        tar xf ${CACHE_FILE}/core.files.tar.gz -C ${CACHE_FILE} > /dev/null 2>&1;
        tar xf ${CACHE_FILE}/multilib.files.tar.gz -C ${CACHE_FILE} > /dev/null 2>&1;
        tar xf ${CACHE_FILE}/extra.files.tar.gz -C ${CACHE_FILE} > /dev/null 2>&1;

        touch "${DEPS_FILE}"
      fi
}

function ask_to_continue {
    if [ "$ADD_AS_DEPS" = false ]; then
          if [ "$PRINT_LOG" = true ]; then
             echo -en "\n${NC}Voulez vous procéder a l'installation ? ----- [Y/N]: "
          fi
          read -r asking
          if [[ "${asking}" == "N" || "${asking}" == "n" ]]; then
               if [ "$PRINT_LOG" = true ]; then
                   echo -e "${ORANGE}Arret de l'installation${NC}"
               fi
               rm -rf /etc/cydramanager
               exit 0
          fi
    fi
}


function ask_to_remove {
    if [ "$ADD_AS_DEPS" = false ]; then
          if [ "$PRINT_LOG" = true ]; then
             echo -e  "${ORANGE}Paquet a déinstaller: ${GREEN}${RPKG_NAME}${NC}"
             echo -en "\n${NC}Voulez vous procéder a la déinstallation ? ----- [Y/N]: "
          fi
          read -r asking
          if [[ "${asking}" == "N" || "${asking}" == "n" ]]; then
               if [ "$PRINT_LOG" = true ]; then
                   echo -e "${ORANGE}Arrêt de l'installation${NC}"
               fi
               rm -rf /etc/cydramanager
               exit 0
          fi
    fi
}

function install_ask_to_continue {
    if [ "$ADD_AS_DEPS" = false ]; then
        echo -en "${ORANGE}Paquets a installer: ${GREEN}${PKG_NAME}${ORANGE}\nDépendances: ${NC}"
        depsList=()
        readState=0
        while IFS= read -r line; do
                if [ ${readState} == 1 ]; then
                        if [ -z "${line}" ]; then
                                break
                        fi

                        if [[ ! ${line} =~ "=" ]]; then
                           depsList+=("${line}")
                        fi
                fi

                if [[ "${line}" == "%DEPENDS%" ]]; then
                        readState=1
                fi
        done < "${PKG_INFO}"

        for element in "${depsList[@]}"; do
                 echo "${element}" > ${DEPS_FILE}
                 echo -en "${NC}${element} "
                 DEPS_COUNTER=$((DEPS_COUNTER+1))
        done
        DEPS_NUMBER=$(wc -l ${DEPS_FILE} | awk '{print $1}')
        for ((i=1; i<=DEPS_NUMBER; i++)); do
                DEPS_NAME=$(sed -n "${i}p" "${DEPS_FILE}")
        done
        if [ "$PRINT_LOG" = true ]; then
           echo
           DEPS_COUNTER=$((DEPS_COUNTER + 1))
           echo -e "${NC}\nTotal des paquets a installer: ${DEPS_COUNTER}"
           echo -en "\n${NC}Voulez vous procéder a l'installation ? ----- [Y/N]: "
        fi
        unset DEPS_NUMBER DEPS_COUNTER depsList readState line
        read -r asking
        if [[ "${asking}" == "N" || "${asking}" == "n" ]]; then
             if [ "$PRINT_LOG" = true ]; then
                 echo -e "${ORANGE}Arrêt de l'installation${NC}"
             fi
             rm -rf /etc/cydramanager
             exit 0
        fi
  fi
}

function fetch_warninglog {
    if [ "$PRINT_LOG" = true ]; then
       echo -e "${ORANGE}UTILISÉ UN MIRROR PERSONALISÉE PEU CREER DES FAILLES DE SECURITÉS IMPORTANTES, UTILISEZ LES UNIQUEMENT SI VOUS EN AVEZ CONFIANCE!\n\n ${NC}"
       echo -e "${GREEN}Le mirror $(cat /etc/cydrafetch/currentMirror) sera utilisé par le gestionnaire de paquet${NC}"
    fi
}

function update_ipacket {
  for tp in ${updatedir}; do
        echo -n "Traitement du paquet: ${tp}"
        tp_name=(basename "${tp}")
        if [[ $(cat "${tp}") == $(cat "/usr/cydramanager/currentSoftware/${tp_name}/cydramanager_pkgver") ]]; then
            echo -e "${NC} ${tp}-[A JOUR]"
        else
            if [[ -e /usr/cydramanager/oldSoftware/${tp_name}/ ]]; then
                 mv "/usr/cydramanager/currentSoftware/${tp_name}/*" "/usr/cydramanager/oldSoftware/${tp_name}"

                 UPKG_INFO=$(grep -r -l -m 1 -o "${tp_name}-" /etc/cydramanager/cache | head -1)
                 UPKG_VERSION=$(sed -n 11p "${UPKG_INFO}")
                 UPKG_ARCHIVE=$(sed -n 2p "${UPKG_INFO}")
                 UPKG_SIG=$(sed -n 23p "${UPKG_INFO}")

                 wget "${POOL_DL}/${UPKG_ARCHIVE}" -P /usr/cydramanager/pkgt --no-check-certificate -q
                 tar xf "/usr/cydramanager/pkgt/${UPKG_ARCHIVE}" -C "/usr/cydramanager/currentSoftware/${tp_name}"
                 md5sum "/usr/cydramanager/pkgt/${UPKG_ARCHIVE}" | cut -d ' ' -f 1 > "/usr/cydramanager/currentSoftware/${tp_name}/cydramanager_md5sig"
                 echo "${UPKG_VERSION}" > "/usr/cydramanager/currentSoftware/${tp_name}/cydramanager_pkgver"
                 find "/etc/cydramanager/cache" -type f -name "desc" -exec rm -f {} +
                 RPKG_INFO=$(grep -r -l -m 1 -o "$PACKAGE-" /etc/cydramanager/cache | head -1)
                 for pkgfiles in $(cat ${RPKG_INFO}); do
                     if [ -e "$pkgfiles" ]; then
                         rm -f "$pkgfiles"
                     fi
                 done
                 cp -r "/usr/cydramanager/currentSoftware/${tp_name}/*" "/"
                 rm -f "/usr/cydramanager/pkgt/${UPKG_ARCHIVE}"
                 echo -e "${NC} ${tp} ${GREEN}[A JOUR]"
            else
                 rm -rf "/usr/cydramanager/oldSoftware/${tp_name}/*"
                 mv "/usr/cydramanager/currentSoftware/${tp_name}/*" "/usr/cydramanager/oldSoftware/${tp_name}"

                 UPKG_INFO=$(grep -r -l -m 1 -o "${tp_name}-" /etc/cydramanager/cache | head -1)
                 UPKG_VERSION=$(sed -n 11p "${UPKG_INFO}")
                 UPKG_SIG=$(sed -n 23p "${UPKG_INFO}")

                 wget "${POOL_DL}/${UPKG_ARCHIVE}" -P /usr/cydramanager/pkgt --no-check-certificate -q
                 tar xf "/usr/cydramanager/pkgt/${UPKG_ARCHIVE}" -C "/usr/cydramanager/currentSoftware/${tp_name}"
                 md5sum "/usr/cydramanager/pkgt/${UPKG_ARCHIVE}" | cut -d ' ' -f 1 > "/usr/cydramanager/currentSoftware/${tp_name}/cydramanager_md5sig"
                 echo "${UPKG_VERSION}" > "/usr/cydramanager/currentSoftware/${tp_name}/cydramanager_pkgver"
                 cp -r "/usr/cydramanager/currentSoftware/${tp_name}/*" "/"
                 rm -f "/usr/cydramanager/pkgt/${UPKG_ARCHIVE}"
                 echo -e "${NC} ${tp} ${GREEN}[A JOUR]"
            fi
        fi
    done
}

function install_packet {
    wget "${POOL_DL}/${PKG_ARCHIVE}" -P "${INSTALL_DIR}" --no-check-certificate -q

    chmod +rwx "${INSTALL_DIR}${PKG_ARCHIVE}"
    tar xf "${INSTALL_DIR}${PKG_ARCHIVE}" -C "/usr/cydramanager/pkgt" 2> /dev/null
    for packageFilter in /usr/cydramanager/pkgt/usr/*; do
       if [ "$(basename "${packageFilter}")" != "bin" ]; then
           mv "${packageFilter}" / 2> /etc/cydramanager/cache/smthawful.log
       fi
    done
    rm -rf "/usr/cydramanager/pkgt/*"
    wget "${POOL_DL}/${PKG_ARCHIVE}" -P "${INSTALL_DIR}" --no-check-certificate -q
    tar xf "${INSTALL_DIR}${PKG_ARCHIVE}" -C "/usr/cydramanager/pkgt"
    tar xf "${INSTALL_DIR}${PKG_ARCHIVE}" -C "/" 
    EXTRACTED_ARCHIVE=$(ls "/usr/cydramanager/pkgt")
    mkdir /usr/cydramanager/currentSoftware/"${PKG_NAME}"
    mkdir "/usr/cydramanager/oldSoftware/${PKG_NAME}"
    touch "/usr/cydramanager/currentSoftware/${PKG_NAME}/cydramanager_md5sig"
    md5sum "${INSTALL_DIR}${PKG_ARCHIVE}" | cut -d ' ' -f 1 > "/usr/cydramanager/currentSoftware/${PKG_NAME}/cydramanager_md5sig"
    touch "/usr/cydramanager/currentSoftware/${PKG_NAME}/cydramanager_pkgver"
    echo "${PKG_VERSION}" > "/usr/cydramanager/currentSoftware/${PKG_NAME}/cydramanager_pkgver"
    softwareListed=("$(ls "/usr/cydramanager/pkgt/$EXTRACTED_ARCHIVE")")
    cp -r /usr/cydramanager/pkgt/"${EXTRACTED_ARCHIVE}"/* /usr/cydramanager/currentSoftware/"${PKG_NAME}"
    rm -rf /usr/cydramanager/pkgt/*
    for potentialexecutable in $(find "/usr/cydramanager/currentSoftware/${PKG_NAME}" -type f); do
        if [[ -x ${potentialexecutable} ]]; then
           ln -sf "${potentialexecutable}" "/usr/bin"
        fi
    done
    
    touch ${USER_INSTALLED_SOFTWARE_DIR}/"${PKG_NAME}"
    echo "${PKG_VERSION}" > ${USER_INSTALLED_SOFTWARE_DIR}/"${PKG_NAME}"
}
    depsList=()
    readState=0

function install_deps {
    while IFS= read -r line; do

        if [ $readState -eq 1 ]; then
            if [ -z "$line" ]; then
                break
            fi
            depsList+=("$line")
        fi

        if [[ "$line" == "%DEPENDS%" ]]; then
            readState=1
        fi
    done < "${PKG_INFO}"

    for element in "${depsList[@]}"; do
          echo "${element}" > ${DEPS_FILE}
    done
    DEPS_NUMBER=$(wc -l ${DEPS_FILE} | awk '{print $1}')
    for ((i=1; i<=DEPS_NUMBER; i++)); do
        MDEPS_NAME="${i}"
        DEPS_NAME=$(sed -n "${i}p" "${DEPS_FILE}")
        DEPS_INFO=$(grep -r -l -m 1 -o "$DEPS_NAME-" /etc/cydramanager/cache | head -1)
        DEPS_VERSION=$(sed -n 11p "${DEPS_INFO}")
        DEPS_ARCHIVE=$(sed -n 2p "${DEPS_INFO}")

        if [[ -z ${DEPS_INFO} ]]; then
          echo -e "${ORANGE}La dépendance ${DEPS_NAME} n'est pas trouvé dans la base de données..${NC}"
          rm -rf /etc/cydramanager
          exit 65
        fi

        wget "${POOL_DL}/${DEPS_ARCHIVE}" -P ${INSTALL_DIR} --no-check-certificate -q

        chmod +rwx "${INSTALL_DIR}${DEPS_ARCHIVE}"

        tar xf "${INSTALL_DIR}${DEPS_ARCHIVE}" -C /

        VERSION=$(cat "${USER_INSTALLED_SOFTWARE_DIR}/${DEPS_NAME}" 2> /etc/cydramanager/cache/smthawful.log)
        if ! [ "$VERSION" = "$DEPS_VERSION" ]; then
            touch ${USER_INSTALLED_SOFTWARE_DIR}/"${DEPS_NAME}"
            echo "${DEPS_VERSION}" > "${USER_INSTALLED_SOFTWARE_DIR}/${DEPS_NAME}"
        fi

        VERSION=$(cat "${INSTALLED_SOFTWARE_DIR}/${DEPS_NAME}" 2> /etc/cydramanager/cache/smthawful.log)
        if ! [ "$VERSION" = "$DEPS_VERSION" ]; then
            touch ${USER_INSTALLED_SOFTWARE_DIR}/"${DEPS_NAME}"
            echo "${DEPS_VERSION}" > "${USER_INSTALLED_SOFTWARE_DIR}/${DEPS_NAME}"
        fi

   done
}

function firstupdate_wash {
  rm -rf ${CACHE_FILE}/core.*
  rm -rf ${CACHE_FILE}/*.pkg.tar.zst.sig

  rm -rf "${CACHE_FILE}/coreutils-9.4-2-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/coreutils-9.4-2-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/archlinux-keyring-20231026-1-any.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/bash-5.2.015-5-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/efibootmgr-18-2-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/efivar-38-3-x86_64.pkg.tar.zst.sig"
  rm -rf "${CACHE_FILE}/gc-8.2.4-1-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/gcc-13.2.1-3-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/gcc-ada-13.2.1-3-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/gcc-d-13.2.1-3-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/gcc-fortran-13.2.1-3-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/gcc-go-13.2.1-3-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/gcc-libs-13.2.1-3-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/glib2-2.78.1-1-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/glib2-docs-2.78.1-1-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/glibc-2.38-7-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/glibc-locales-2.38-7-x86_64.pkg.tar.zst"
  if [[ "$INSTALL_PACMAN" == true ]]; then
    rm -rf "${CACHE_FILE}/pacman-6.0.2-8-x86_64.pkg.tar.zst"
    rm -rf "${CACHE_FILE}/pacman-mirrorlist-20231001-1-any.pkg.tar.zst"
  fi
  rm -rf "${CACHE_FILE}/shadow-4.14.2-1-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/util-linux-2.39.2-1-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/util-linux-libs-2.39.2-1-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/linux-*"
  rm -rf "${CACHE_FILE}/arch64-linux-*"
  rm -rf "${CACHE_FILE}/dbus-1.14.10-2-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/dbus-broker-36-2-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/dbus-broker-units-36-2-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/dbus-daemon-units-1.14.10-2-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/dbus-docs-1.14.10-2-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/inetutils-2.5-1-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/iproute2-6.9.0-1-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/iptables-1:1.8.10-1-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/iptables-nft-1:1.8.10-1-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/iputils-20240117-1-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/iw-6.9-1-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/systemd-255.7-1-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/systemd-libs-255.7-1-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/systemd-resolvconf-255.7-1-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/systemd-sysvcompat-255.7-1-x86_64.pkg.tar.zst"
  rm -rf "${CACHE_FILE}/systemd-ukify-255.7-1-x86_64.pkg.tar.zst"
  rm -rf "/etc/cydramanager/cache/core.db"
  rm -rf "/etc/cydramanager/cache/core.db.tar.gz"
  rm -rf "/etc/cydramanager/cache/core.db.tar.gz.old"
  rm -rf "/etc/cydramanager/cache/core.db.files"
  rm -rf "/etc/cydramanager/cache/core.db.files.tar.gz"
  rm -rf "/etc/cydramanager/cache/core.db.files.tar.gz.old"
  rm -rf "/etc/cydramanager/cache/index.html"
  rm -rf "/etc/cydramanager/cache/x86_64"
  rm -rf "/etc/cydramanager/cache/lib32-dbus-1.14.10-2-x86_64.pkg.tar.zst"
  rm -rf "/etc/cydramanager/cache/lib32-dbus-glib-0.112-2-x86_64.pkg.tar.zst"
  rm -rf "/etc/cydramanager/cache/lib32-libdbusmenu-glib-16.04.0-5-x86_64.pkg.tar.zst"
  rm -rf "/etc/cydramanager/cache/lib32-libdbusmenu-gtk2-16.04.0-5-x86_64.pkg.tar.zst"
  rm -rf "/etc/cydramanager/cache/lib32-libdbusmenu-gtk3-16.04.0-5-x86_64.pkg.tar.zst"
  rm -rf "/etc/cydramanager/cache/lib32-systemd-255.7-1-x86_64.pkg.tar.zst"
  rm -rf "/etc/cydramanager/cache/lib32-polkit-124-1-x86_64.pkg.tar.zst"
  if dmesg | grep -iq nvidia; then
     rm -f /etc/cydramanager/cache/amdvlk-*.pkg.tar.zst
     rm -f /etc/cydramanager/cache/hip-runtime-amd-*.pkg.tar.zst
     rm -f /etc/cydramanager/cache/hsa-amd-aqlprofile-bin-*.pkg.tar.zst
     rm -f /etc/cydramanager/cache/xf86-video-amdgpu-*.pkg.tar.zst
     rm -f /etc/cydramanager/cache/lib32-amdvlk-2024.Q2.1-1-x86_64.pkg.tar.zst
  elif dmesg | grep -iq amd; then
     rm -f /etc/cydramanager/cache/libnvidia-container-*.pkg.tar.zst
     rm -f /etc/cydramanager/cache/libva-nvidia-driver-*.pkg.tar.zst
     rm -f /etc/cydramanager/cache/nvidia-*-x86_64.pkg.tar.zst
     rm -f /etc/cydramanager/cache/nvidia-cg-toolkit-*.pkg.tar.zst
     rm -f /etc/cydramanager/cache/nvidia-container-toolkit-*.pkg.tar.zst
     rm -f /etc/cydramanager/cache/nvidia-dkms-*-x86_64.pkg.tar.zst
     rm -f /etc/cydramanager/cache/nvidia-*-x86_64.pkg.tar.zst
     rm -f /etc/cydramanager/cache/nvidia-open-*-x86_64.pkg.tar.zst    
     rm -f /etc/cydramanager/cache/nvidia-prime-*-any.pkg.tar.zst
     rm -f /etc/cydramanager/cache/nvidia-settings-*-x86_64.pkg.tar.zst
     rm -f /etc/cydramanager/cache/nvidia-utils-*-x86_64.pkg.tar.zst
     rm -f /etc/cydramanager/cache/opencl-nvidia-*-x86_64.pkg.tar.zst
     rm -f /etc/cydramanager/cache/lib32-nvidia-cg-toolkit-3.1-8-x86_64.pkg.tar.zst
     rm -f /etc/cydramanager/cache/lib32-nvidia-utils-550.78-2-x86_64.pkg.tar.zst
     rm -f /etc/cydramanager/cache/lib32-opencl-nvidia-550.78-2-x86_64.pkg.tar.zst
   fi
}

function check_fupdatedisk {
  > "/etc/cydraterms/firstupdate.log"

  if [[ "$VERBOSE" == true ]]; then
      cat /etc/cydraterms/firstupdate.log
  fi

  USERDISK_MAXSIZE=$(df --output=avail / | tail -n 1)
  USERDISK_MAXSIZE=$(( USERDISK_MAXSIZE / 1024 ))

  USAGE_SIZE=$(du -sm /usr | cut -f1)

  TOTAL_REQUIRED_SPACE=$(( (4 * USAGE_SIZE) ))

  if (( TOTAL_REQUIRED_SPACE > USERDISK_MAXSIZE )); then
      echo -e "${RED}Votre système manque d'espace disque pour installer la mise à jour..${NC}"
      rm -rf /etc/cydramanager
      exit 1
  else
      echo -e "${NC}Espace disque nécessaire pour la mise à jour: ${TOTAL_REQUIRED_SPACE} Mo"
  fi

  rm -rf "/etc/cydramanager/cache/*"
}

if [ "$SHOW_HELP" = true ]; then
   if [ "$PRINT_LOG" = true ]; then
      open_help
   fi
fi

if [ "$PRINT_MIRROR" = true ]; then
   if [ "$PRINT_LOG" = true ]; then
      echo "${MIRROR_URL}"
      exit 0
   fi
fi

if [[ "$1" != "install" && "$1" != "remove" && "$1" != "update" && "$1" != "fetch" && "$1" != "help" && "$1" != "version" && "$1" != "patchnote" && "changever" != "$1" ]]; then
    if [ "$PRINT_LOG" = true ]; then
      echo -e "${RED}L'action est invalide. Etes vous perdu? \n cydramanager -h pour ouvrir la liste des commandes / arguments disponibles !${NC}"
      exit 5
    fi
fi

if [[ ! "${CURRENT_GDP_VERSION}" == "${GDP_VERSION}" ]]; then
    echo -e "${ORANGE}Une nouvelle version du gestionnaire de paquets est en ligne.${NC}"
fi

rm -rf /etc/cydramanager 2> /dev/null
if [[ "$1" == "install" ]]; then
    if [ ! -f "/etc/cydraterms/firstupdated" ]; then
        echo -e "${RED}Le gestionnaire de paquets ne fonctionnera pas si la 1ere mise a jour n'a pas été effectuée..: ${ORANGE}cydramanager update${NC}"
    fi

    if ! [[ -d ${CACHE_FILE} ]]; then
       mkdir -p ${CACHE_FILE}
       mkdir -p ${INSTALL_DIR}
    elif [ "$WASH_CACHE" = true ]; then
         rm -rf "${CACHE_FILE:?}/*"
         rm -rf "${INSTALL_DIR:?}*"
    fi

    update_db

    PKG_INFO=$(grep -r -l -m 1 -o "$PACKAGE-" /etc/cydramanager/cache | head -1)
    PKG_VERSION=$(sed -n 11p "${PKG_INFO}")
    PKG_ARCHIVE=$(sed -n 2p "${PKG_INFO}")
    PKG_NAME=$(sed -n 5p "${PKG_INFO}")

    if [ "$ADD_AS_DEPS" = false ]; then
        if [[ -z ${PKG_INFO} ]]; then
            echo -e "${RED}Le paquet ${PACKAGE} n'est pas trouver dans la base de données..${NC}"
            rm -rf "/etc/cydramanager"
            exit 22
        fi
    fi

    VERSION=$(cat "${INSTALLED_SOFTWARE_DIR}/${PKG_NAME}" 2> /etc/cydramanager/cache/smthawful.log)
    if [ "${PKG_VERSION}" = "${VERSION}" ]; then
        echo -e "${RED}Erreur: Le paquet ${PKG_NAME} version ${PKG_VERSION} est déjà installé sur votre système.${NC}"
        rm -rf "/etc/cydramanager"
        exit 5
    elif [ -n "${VERSION}" ]; then
        mv /usr/cydramanager/currentSoftware/"${PKG_NAME}"/* /usr/cydramanager/oldSoftware/"${PKG_NAME}"
        rm -f /etc/cydraterms/userSoftware/"${PKG_NAME}"
        echo -e "${ORANGE}Votre paquet ${PACKAGE} est dans une version obsêlete (${PKG_VERSION}). La nouvelle version ${VERSION} va être installé..${NC}"
        mv "/usr/cydramanager/currentSoftware/${PKG_NAME}/*" "/usr/cydramanager/oldSoftware/${PKG_NAME}"
    fi

    VERSION=$(cat "${USER_INSTALLED_SOFTWARE_DIR}/${PKG_NAME}" 2> /etc/cydramanager/cache/smthawful.log)
    if [ "${PKG_VERSION}" = "${VERSION}" ]; then
        echo -e "${RED}Erreur: Le paquet ${PKG_NAME} version ${PKG_VERSION} est déjà installé sur votre système.${NC}"
        rm -rf "/etc/cydramanager"
        exit 5
    elif [ -n "${VERSION}" ]; then
        mv /usr/cydramanager/currentSoftware/"${PKG_NAME}"/* /usr/cydramanager/oldSoftware/"${PKG_NAME}"
        rm -f /etc/cydraterms/userSoftware/"${PKG_NAME}"
        echo -e "${ORANGE}Votre paquet ${PACKAGE} est dans une version obsêlete (${PKG_VERSION}) LA nouvelle version ${VERSION} va etre installé..${NC}"
    fi

    if ! [[ -f "${CACHE_FILE}/core.db.tar.gz" || -f "${CACHE_FILE}/multilib.db.tar.gz" || -f "${CACHE_FILE}/extra.db.tar.gz" || -f "${CACHE_FILE}/cydra.tar.gz" ]]; then
         if [ "$PRINT_LOG" = true ]; then
             echo -e "${RED}Des fichiers obligatoires pour la mise en point de la base de donnee sont introuvables..\nEtes vous sur d'etre connecte a internet ?\n\nSi oui la raison peu venir d'un mirror defecteux pour le reparer utilisez \n cydramanager fetch${NC}"
         fi
         exit 1
    fi

    install_ask_to_continue

    install_packet
    install_deps


    if [ "${WASH_CACHE}" = true ]; then
       rm -rf "/etc/cydramanager"
    fi
elif [[ "$1" == "remove" ]]; then
    if [ ! -f "/etc/cydraterms/firstupdated" ]; then
        echo -e "${RED}Le gestionnaire de paquets ne fonctionnera pas si la 1ere mise a jour n'a pas été effectuée..: ${ORANGE}cydramanager update${NC}"
    fi

    if ! [[ -d ${CACHE_FILE} ]]; then
       mkdir -p ${CACHE_FILE}
       mkdir -p ${INSTALL_DIR}
    elif [ "$WASH_CACHE" = true ]; then
         rm -rf ${CACHE_FILE:?}/*
         rm -rf ${INSTALL_DIR:?}*
    fi

    update_db
    RePKG_INFO=$(grep -r -l -m 1 -o "$PACKAGE-" /etc/cydramanager/cache | head -1)
    RPKG_NAME=$(sed -n 5p "${RePKG_INFO}")
    rm -rf /etc/cydramanager
    update_db_files
    find "/etc/cydramanager/cache" -type f -name "desc" -exec rm -f {} +

    RPKG_INFO="${RePKG_INFO:0:-4}files"
    RPKG_INFO_FULL=$(sed 's|^|/|' "${RPKG_INFO}")
    RPKG_NMB=$(wc -l < "${RPKG_INFO}")
    sed -i 1d "${RPKG_INFO}"
    if [ ! -d "/usr/cydramanager/currentSoftware/${RPKG_NAME}" ]; then
        echo -e "${RED}Le paquet ${PACKAGE} n'est pas installé sur votre système..${NC}"
        rm -rf /etc/cydramanager
        exit 5
    fi

    ask_to_remove

    rm -f "/etc/cydraterms/usersoftware/${RPKG_NAME}"
    rm -rf "/usr/cydramanager/oldSoftware/${RPKG_NAME}"
    rm -rf "/usr/cydramanager/currentSoftware/${RPKG_NAME}"

    echo "${RPKG_INFO_FULL}" | grep -vE '/$' | while read -r pkgfile; do
         if [ -f "${pkgfile}" ]; then
             unlink "${pkgfile}"
         fi
    done

    if [ "$VERBOSE" = false ]; then
        for ((i=0; i<RPKG_NMB; i++)); do
              PERCENT=$(( (i+1) * 100 / RPKG_NMB ))
              printf "[${RPKG_NAME}] Suppression : ["
              for ((j=0; j<50; j+=2)); do
                  if [ $j -lt $((PERCENT/2)) ]; then
                      printf "#"
                  else
                      printf " "
                  fi
              done
              printf "] %d%%\r" "$PERCENT"
          done
          echo
      fi

      rm -rf /etc/cydramanager
elif [[ "$1" == "version" ]]; then
  if [ "$PRINT_LOG" = true ]; then
     wget "https://raw.githubusercontent.com/acth2/CydraProject/main/packagemanager/version" -P /etc/cydrafetch/version --no-check-certificate -q
     echo "Cydramanager: $(cat /etc/cydrafetch/version/version)"
     rm -f /etc/cydrafetch/version/version
  fi
elif [[ "$1" == "fetch" ]]; then
  if [ "$PRINT_LOG" = true ]; then
     echo -e "${GREEN}Mise a jour du menu fetch${NC}"
  fi

  rm -f /etc/cydrafetch/1.mirror
  rm -f /etc/cydrafetch/2.mirror
  rm -f /etc/cydrafetch/3.mirror
  rm -f /etc/cydrafetch/4.mirror

  wget "${PM_URL}"/fetch/1.mirror -P ${FETCH_DIR} --no-check-certificate -q
  wget "${PM_URL}"/fetch/2.mirror -P ${FETCH_DIR} --no-check-certificate -q
  wget "${PM_URL}"/fetch/3.mirror -P ${FETCH_DIR} --no-check-certificate -q
  wget "${PM_URL}"/fetch/4.mirror -P ${FETCH_DIR} --no-check-certificate -q

  firstMirror=$(cat /etc/cydrafetch/1.mirror)
  secondMirror=$(cat /etc/cydrafetch/2.mirror)
  thirdMirror=$(cat /etc/cydrafetch/3.mirror)
  lastMirror=$(cat /etc/cydrafetch/4.mirror)

      if [ "$PRINT_LOG" = true ]; then
         echo -e "${GREEN}============================= INTERFACE FETCH                                                                  ${NC}"
         echo -e "${RED}   OS) ${PM_URL}                                                                                                 ${NC}"
         echo -e "${RED}   1) ${firstMirror}                                                                                             ${NC}"
         echo -e "${RED}   2) ${secondMirror}                                                                                            ${NC}"
         echo -e "${RED}   3) ${thirdMirror}                                                                                             ${NC}"
         echo -e "${RED}   4) ${lastMirror}                                                                                              ${NC}"
         echo -en "${GREEN}   Selectionnez un nombre entre (OS) 1 - 4:                                                                   ${NC}"*
      fi
         read -r fetchRequest
      if [ "$PRINT_LOG" = true ]; then
         echo -e "${GREEN}=============================================                                                                  ${NC}"
      fi

      if [ "${fetchRequest}" == "1" ]; then
          rm -f /etc/cydrafetch/currentMirror
          touch currentMirror
          echo "${firstMirror}" > /etc/cydrafetch/currentMirror

          fetch_warninglog
          exit 0
      elif [ "${fetchRequest}" == "2" ]; then
          rm -f /etc/cydrafetch/currentMirror
          touch currentMirror
          echo "${secondMirror}" > /etc/cydrafetch/currentMirror

          fetch_warninglog
          exit 0
      elif [ "${fetchRequest}" == "3" ]; then
          rm -f /etc/cydrafetch/currentMirror
          touch currentMirror
          echo "${thirdMirror}" > /etc/cydrafetch/currentMirror

          fetch_warninglog
          exit 0
      elif [ "${fetchRequest}" == "4" ]; then
          rm -f /etc/cydrafetch/currentMirror
          touch currentMirror
          echo "${lastMirror}" > /etc/cydrafetch/currentMirror

          fetch_warninglog
          exit 0
      else
          echo -e "${RED}Veuillez choisir l'un de ces 4 mirrors. Votre reponse: ${fetchRequest} est invalide${NC}"
          exit 5
      fi

elif [[ "$1" == "help" ]]; then
    if [ ! -f "/etc/cydraterms/firstupdated" ]; then
        echo -e "${ORANGE}/!\\ La 1ere mise a jour n'a pas été effectuée /!\\ ${NC}"
    fi
    open_help
elif [[ "$1" == "update" ]]; then
    if ! [[ -d ${CACHE_FILE} ]]; then
       mkdir -p ${CACHE_FILE}
       mkdir -p ${INSTALL_DIR}
    elif [ "$WASH_CACHE" = true ]; then
         rm -rf ${CACHE_FILE:?}/*
         rm -rf ${INSTALL_DIR:?}*
    fi
  echo -e "${GREEN}Lancement de la mise a jour${NC}"
  if [[ -n ${3} ]]; then
       if [[ "$3" == "cydramanager" ]]; then
           echo -e "${GREEN}Lancement de la mise a jour du gestionnaire de paquets${NC}"
           if [[ "${CURRENT_GDP_VERSION}" == "${GDP_VERSION}" ]]; then
               echo -e "${NC} cydramanager ${GREEN}[A JOUR]${NC}"
               exit 0
           fi
           rm -f /usr/bin/cydramanager
           wget "https://raw.githubusercontent.com/acth2/CydraProject/main/testing/packagemanagers/software/cydramanager" -P /usr/bin --no-check-certificate -q
           echo -e "${NC} cydramanager ${GREEN}[A JOUR]${NC}"
           exit 0
       fi
       update_db
       UPDATE_INFO=$(grep -r -l -m 1 -o "${3}-" /etc/cydramanager/cache | head -1)
       UPDATE_VERSION=$(sed -n 11p "${UPDATE_INFO}")
       UPDATE_ARCHIVE=$(sed -n 2p "${UPDATE_INFO}")
       UPDATE_NAME=$(sed -n 5p "${UPDATE_INFO}")
       
       VERSION=$(cat "${USER_INSTALLED_SOFTWARE_DIR}/${PKG_NAME}" 2> /etc/cydramanager/cache/smthawful.log)
      if [ "${PKG_VERSION}" = "${VERSION}" ]; then
          echo -e "${NC} ${UPDATE_NAME} ${GREEN}[A JOUR]${NC}"
          rm -rf "/etc/cydramanager"
          exit 5
      elif [ -n "${VERSION}" ]; then
          mv /usr/cydramanager/currentSoftware/"${UPDATE_NAME}"/* /usr/cydramanager/oldSoftware/"${UPDATE_NAME}"
          rm -f /etc/cydraterms/userSoftware/"${UPDATE_NAME}"
          touch /etc/cydraterms/userSoftware/"${UPDATE_NAME}"
          rm -rf "/usr/cydramanager/pkgt/*"
          wget "${POOL_DL}/${UPDATE_ARCHIVE}" -P "/usr/cydramanager/pkgt" --no-check-certificate -q
          updated_archive=$(ls /usr/cydramanager/pkgt)
          tar xf "/usr/cydramanager/pkgt/${updated_archive}" -C "/usr/cydramanager/currentSoftware/${UPDATE_NAME}"
          tar xf "/usr/cydramanager/pkgt/${updated_archive}" -C "/"
          rm -rf "/usr/cydramanager/pkgt/*"
          echo -e "${NC} ${tp} ${GREEN}[A JOUR]${NC}"
      fi

      rm -rf /etc/cydramanager
      exit 0
  fi
  if [[ ! -f "/etc/cydraterms/firstupdated" ]]; then
      echo -e "${GREEN}Installation de tout les packages de la 1ere mise a jour${NC}"
      echo -e "${NC}Initialisation de la 1ere mise a jour.."
      echo -e "${NC}Calcul total des paquets.\nCela va prendre du temps."
      UPKG_NMB=$(wget --spider -r -nd -R "*linux*" "${CORE_DL}" 2>&1 | grep -c '^--')
      lfspackages=( $(ls "${INSTALLED_SOFTWARE_DIR}") )
      echo -e "${ORANGE}Branche a installer: ${GREEN}core${NC}"
      echo -e "${ORANGE}Dépendances: ${NC}Aucunes"
      echo
      echo -e "${NC}Total des paquets a installer: ${UPKG_NMB}"
      check_fupdatedisk
      ask_to_continue
      echo -e "${ORANGE}Arreter la mise à jour ici rendra votre système ${RED}inutilisable. ${ORANGE}Agissez avec précautions.${NC}"
      i=0
      wget -r -np -nH --cut-dirs=4 -R "*linux*" "${CORE_DL}" -P "${CACHE_FILE}" -q &
      WGET_PID=$!

      while kill -0 $WGET_PID 2>/dev/null; do
          if [ "$VERBOSE" = false ]; then
              i=$(find "${CACHE_FILE}" -type f | wc -l)

              PERCENT=$(( (i * 100) / UPKG_NMB ))
              printf "[1/2] Téléchargement : ["
              for ((j=0; j<50; j+=2)); do
                  if [ $j -lt $((PERCENT/2)) ]; then
                      printf "#"
                  else
                      printf " "
                  fi
              done
              printf "] %d%%\r" "$PERCENT"
              sleep 1
          fi
      done
      firstupdate_wash
      echo "[1/2] Téléchargement : [#########################] [Protection du systeme]"
      cp -r "/usr/share/*" "/etc/cydramanager/001cydrauserbackup/sharedir"
      cp -r "/usr/bin/*"   "/etc/cydramanager/001cydrauserbackup/usrdir"
      find / -type f -exec chattr +i {} \; 2> /dev/null
      updatepkglist=( $(ls /etc/cydramanager/cache/*.pkg.tar.zst) )
      pkgcounter=0
      UPKG_NMB=${#updatepkglist[@]}

      for updatepkg in "${updatepkglist[@]}"; do
          pkgcounter=$((pkgcounter + 1))

          if [ "$VERBOSE" = false ]; then
              printf "\r"
              printf "                                             "
              printf "\r[2/2] Installation: ["
          fi

          tar xf "${updatepkg}" -C / --skip-old-files --exclude='/usr/lib/systemd/*' --exclude='/lib/systemd/*' --exclude='/etc/systemd/*' --exclude='/usr/include/shadow' --exclude='/etc/default' --exclude='/usr/bin/wpa_supplicant' --exclude='/usr/bin/wpa_cli' --exclude='/usr/bin/wpa_passphrase' 2> /dev/null

          if [ "$VERBOSE" = false ]; then
              PERCENT=$(( (pkgcounter * 100) / UPKG_NMB ))
              for ((j=0; j<50; j+=2)); do
                  if [ $j -lt $((PERCENT / 2)) ]; then
                      printf "#"
                  else
                      printf " "
                  fi
              done
              printf "] %d%%\r" "$PERCENT"
          fi
      done

      if [ "$VERBOSE" = false ]; then
          echo "[2/2] Installation : [#########################] [Finalisation]"
      fi
      mkdir /var/spool/mail/root
      find / -type f -exec chattr -i {} \; 2> /dev/null
      mv /etc/cydramanager/001cydrauserbackup /usr
      ln -s "/lib/systemd/systemd" "/sbin/init" 2> /dev/null
      rm -f "/etc/profile"
      rm -f "/usr/bin/archlinux-keyring-wkd-sync"
      if [[ "$INSTALL_PACMAN" == true ]]; then
        rm -f "/usr/bin/pacman"
        rm -f "/usr/bin/pacman-conf"
        rm -f "/usr/bin/pacman-db-upgrade"
        rm -f "/usr/bin/pacman-key"
      fi
      wget "https://raw.githubusercontent.com/acth2/CydraProject/main/packagemanager/installedsoftware/profile" -P /etc --no-check-certificate -q
      touch "/etc/cydraterms/firstupdated"
      printf "Oui tu l'as fait.. Bravo!\nYes you did it.. Congrats!\n" > /etc/cydraterms/firstupdated
      mv "/etc/cydramanager/001cydrauserbackup/sharedir/*" "/usr/share"
      mv "/etc/cydramanager/001cydrauserbackup/usrdir/*" "/usr/bin"
      chattr +i "/etc/cydraterms/firstupdated"
      ln "/lib/systemd/systemd" "/sbin/init" 2> /dev/null
      rm -rf "/etc/cydramanager"
      echo -e "${GREEN}Votre systeme est a jour.. Veuillez le redémarrer votre PC${NC}"
  else
    update_db

    updatedir='/etc/cydraterms/usersoftware/*'
    update_ipacket

    updatedir='/etc/cydraterms/installedsoftware/*'
    update_ipacket
  fi

  if [ "$WASH_CACHE" = true ]; then
      rm -rf "/etc/cydramanager"
  fi
elif [[ "$1" == "patchnote" ]]; then
  echo "Mise a jour du Patchnote."
  wget "https://raw.githubusercontent.com/acth2/CydraProject/main/packagemanager/changelogs.log" -P /etc/cydraterms --no-check-certificate -q
  cat /etc/cydraterms/changelogs.log
elif [[ "$1" == "changever" ]]; then
     if [[ -z $2 ]]; then
         echo -e "${RED}Un paquet a besoin d'être spécifié !${NC}"
         exit 5
     fi

     update_db

     PKG_INFO=$(grep -r -l -m 1 -o "$PACKAGE-" /etc/cydramanager/cache | head -1)
     PKG_VERSION=$(sed -n 11p "${PKG_INFO}")
     PKG_NAME=$(sed -n 5p "${PKG_INFO}")
     PKG_SIG=$(sed -n 23p "${PKG_INFO}")

     if [ ! -f /etc/cydraterms/usersoftware/"${PKG_NAME}" ]; then
         echo -e "${RED}Le paquet ${PACKAGE} n'est pas installé sur votre système..${NC}"
         rm -rf /etc/cydramanager
         exit 5
     fi
elif [[ ${3} == "back" ]]; then 
    echo -e "${ORANGE}En construction..${NC}"
fi


if [ "$VERBOSE" = true ]; then
   set +x
fi

exit 0
