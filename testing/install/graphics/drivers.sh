#!/bin/bash

export PKG_CONFIG_PATH="/usr/lib/pkgconfig"
export CFLAGS="-I/home/linuxbrew/.linuxbrew/include $CFLAGS"

XORG_PREFIX="/home/linuxbrew/.linuxbrew"
XORG_CONFIG="--prefix=$XORG_PREFIX --sysconfdir=/home/linuxbrew/.linuxbrew/etc --localstatedir=/home/linuxbrew/.linuxbrew/var"

sudo chmod +rwx /usr/bin/brew
chmod +rwx /usr/bin/brew
/usr/bin/brew
/home/linuxbrew/.linuxbrew/bin/brew install xorg-server
/home/linuxbrew/.linuxbrew/bin/brew install xcb-util
/home/linuxbrew/.linuxbrew/bin/brew install pciutils
/home/linuxbrew/.linuxbrew/bin/brew install xinit

install_from_source() {
    local url=$1
    local build_commands=$2
    local archive_name=$(basename "$url")

    echo "Downloading $archive_name..."
    wget $url -O $archive_name

    echo "Extracting $archive_name..."
    tar -xf $archive_name

    local dir_name=$(tar -tf $archive_name | head -n 1 | cut -d'/' -f1)
    cd $dir_name

    echo "Building $dir_name..."
    eval "$build_commands"

    cd ..
    rm -rf $archive_name $dir_name
    read -p 'Did you just called me a nerd, geek?' nerd
}

install_from_source "https://bitmath.org/code/mtdev/mtdev-1.1.6.tar.bz2" "
    ./configure --prefix=/usr --disable-static &&
    make &&
    sudo make install
"

export CFLAGS=""
install_from_source "https://www.freedesktop.org/software/libevdev/libevdev-1.13.0.tar.xz" "
    mkdir build &&
    cd build &&
    meson --prefix=$XORG_PREFIX --buildtype=release -Ddocumentation=disabled &&
    ninja &&
    sudo ninja install
"

export CFLAGS="-I/home/linuxbrew/.linuxbrew/include $CFLAGS"
install_from_source "https://www.x.org/pub/individual/driver/xf86-input-evdev-2.10.6.tar.bz2" "
    ./configure $XORG_CONFIG &&
    make &&
    sudo make install
"

install_from_source "https://gitlab.freedesktop.org/libinput/libinput/-/archive/1.21.0/libinput-1.21.0.tar.gz" "
    mkdir build &&
    cd build &&
    meson --prefix=$XORG_PREFIX --buildtype=release -Ddebug-gui=false -Dtests=false -Dlibwacom=false -Dudev-dir=/usr/lib/udev .. &&
    ninja &&
    sudo ninja install
"

install_from_source "https://www.x.org/pub/individual/driver/xf86-input-libinput-1.2.1.tar.xz" "
    ./configure $XORG_CONFIG &&
    make &&
    sudo make install
"

install_from_source "https://www.x.org/pub/individual/driver/xf86-input-synaptics-1.9.2.tar.xz" "
    ./configure $XORG_CONFIG &&
    make &&
    sudo make install
"

install_from_source "https://github.com/linuxwacom/xf86-input-wacom/releases/download/xf86-input-wacom-1.1.0/xf86-input-wacom-1.1.0.tar.bz2" "
    ./configure $XORG_CONFIG &&
    make &&
    sudo make install
"

install_from_source "https://www.x.org/pub/individual/driver/xf86-video-fbdev-0.5.0.tar.bz2" "
    ./configure $XORG_CONFIG &&
    make &&
    sudo make install
"

GPU_VENDOR=$(lspci | grep -e VGA -e 3D | grep -oP '(AMD|NVIDIA|Intel|VMware|VirtualBox)')

echo "Detected GPU Vendor: $GPU_VENDOR"
sleep 2
case $GPU_VENDOR in
    AMD)
        install_from_source "https://www.x.org/pub/individual/driver/xf86-video-ati-19.1.0.tar.bz2" "
            patch -Np1 -i xf86-video-ati-19.1.0-upstream_fixes-1.patch &&
            ./configure $XORG_CONFIG &&
            make &&
            sudo make install
        "
        ;;
    NVIDIA)
        install_from_source "https://www.x.org/pub/individual/driver/xf86-video-nouveau-1.0.17.tar.bz2" "
            grep -rl slave | xargs sed -i s/slave/secondary/ &&
            ./configure $XORG_CONFIG &&
            make &&
            sudo make install
        "
        ;;
    Intel)
        install_from_source "https://anduin.linuxfromscratch.org/BLFS/xf86-video-intel/xf86-video-intel-20210222.tar.xz" "
            ./autogen.sh $XORG_CONFIG --enable-kms-only --enable-uxa --mandir=/usr/share/man &&
            make &&
            sudo make install &&
            mv -v /usr/share/man/man4/intel-virtual-output.4 /usr/share/man/man1/intel-virtual-output.1 &&
            sed -i '/\.TH/s/4/1/' /usr/share/man/man1/intel-virtual-output.1
        "
        ;;
    VMware)
        install_from_source "https://www.x.org/pub/individual/driver/xf86-video-vmware-13.3.0.tar.bz2" "
            sed -i 's/>yuv.i/>yuv[j][i/' vmwgfx/vmwgfx_tex_video.c &&
            ./configure $XORG_CONFIG &&
            make &&
            sudo make install
        "
        ;;
    VirtualBox)
        wget "https://download.virtualbox.org/virtualbox/7.0.10/VBoxGuestAdditions_7.0.10.iso"
        mkdir vbox
        sudo mount -o loop VBoxGuestAdditions_7.0.10.iso vbox/
        guesthomedir=$(pwd)
        cd vbox
        vboxdriverdir=$(pwd)
        brew install gnu-which@2.21
        sudo ln /home/linuxbrew/.linuxbrew/Cellar/gnu-which/2.21/bin/which /usr/bin/which
        cd /sources
        sudo wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.19.2.tar.xz
        sudo tar xf "linux-5.19.2.tar.xz"
        cd "linux-5.19.2"
        sudo make mrproper
        sudo make headers
        sudo find usr/include -type f ! -name '*.h' -delete
        sudo cp -rv usr/include /usr
        cd ${vboxdriverdir}
        sudo ./VBoxLinuxAdditions.run
        sudo /sbin/rcvboxadd quicksetup all
        sudo rm -rf "/sources/*"
        sudo rm -rf "${guesthomedir}/*"
        ;;
    *)
        echo "Unknown or unsupported GPU vendor. Please install the drivers manually. (The supported drivers are VMware, Intel, NVIDIA, AMD)"
        sleep 5
        exit 1
        ;;
esac

cd /sources
sudo wget "https://raw.githubusercontent.com/acth2/CydraProject/main/testing/install/graphics/xorg.conf.d/xorg.tar"

sudo rm -rf /etc/X11
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tar xf "/sources/xorg.tar" -C "/etc/X11/xorg.conf.d"

sudo rm -rf /home/linuxbrew/.linuxbrew/etc/X11
sudo mkdir -p /home/linuxbrew/.linuxbrew/etc/X11/xorg.conf.d
sudo tar xf "/sources/xorg.tar" -C "/home/linuxbrew/.linuxbrew/etc/X11/xorg.conf.d"*

sudo rm -f /usr/bin/brew
read -p "Nerd debug (xorg conf)"
