#!/bin/bash

mkdir installation
cd installation
wget https://github.com/lxqt/lxqt-build-tools/releases/download/0.13.0/lxqt-build-tools-0.13.0.tar.xz
tar xf lxqt-build-tools-0.13.0.tar.xz
dir=$(ls)
cd $dir
mkdir -v build &&
cd       build &&

cmake -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE=Release  \
      .. &&

make
sudo make install
cd ../../
rm -rf *
sleep 5

wget https://github.com/lxqt/qtermwidget/releases/download/1.3.0/qtermwidget-1.3.0.tar.xz
tar xf qtermwidget-1.3.0.tar.xz
dir2=$(ls)
cd $dir2
mkdir -v build &&
cd       build &&

cmake -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE=Release  \
      ..       &&
make
sudo make install
cd ../../
rm -rf *
sleep 5

wget https://github.com/lxqt/qterminal/releases/download/1.3.0/qterminal-1.3.0.tar.xz
tar xf qterminal-1.3.0.tar.xz
dir3=$(ls)
cd $dir3
mkdir -v build &&
cd       build &&

cmake -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE=Release  \
      ..       &&

make
sudo make install
