#!/bin/bash

set -ex

# OpenBLAS
# https://github.com/xianyi/OpenBLAS (see README)
if [[ ! -n $(find / -type d -iname openblas -print -quit 2>/dev/null) ]]; then
  cd ~/Documents/
  git clone -b develop https://github.com/xianyi/OpenBLAS.git
  cd OpenBLAS/
  make -j$(nproc --all) BINARY=$(getconf LONG_BIT) CFLAGS='-march=native'
  sudo make install
  echo -e 'export PATH="/opt/OpenBLAS/bin:$PATH"\nexport PKG_CONFIG_PATH="/opt/OpenBLAS/lib/pkgconfig:$PKG_CONFIG_PATH"' >> ~/.bashrc
  source ~/.bashrc
fi

# Torch
# http://torch.ch/docs/getting-started.html
if [ ! -d ~/torch/ ]; then
  git clone --recursive https://github.com/torch/distro.git ~/torch/ --recursive
  cd ~/torch; bash install-deps;
  ./install.sh
fi

# WeBots
# Automatically detect latest WeBots release and download & install for your OS
# IF YOU HAVE UBUNTU 18.04 EXACTLY, THIS WILL NOT WORK (they have a separate release)
if [ -z "${WEBOTS_HOME}" ]; then
  cd ~/Documents/
  if [[ "$OSTYPE" = "linux-gnu"* ]]; then
    RKEY=.tar.bz2
  elif [[ "$OSTYPE" = "darwin"* ]]; then
    RKEY=.dmg
  fi # Windows later; too messy
  curl -s https://api.github.com/repos/cyberbotics/webots/releases/latest \
    | grep browser_download_url.*${RKEY} \
    | grep -v ubuntu \
    | cut -d: -f2,3 \
    | xargs -t wget -i -
  INSTALLER=$(find ./ -type f -iname *webots* -maxdepth 1 -print -quit)
  if [[ "$OSTYPE" = "linux-gnu"* ]]; then
    # https://cyberbotics.com/doc/guide/installation-procedure#installing-the-tarball-package
    tar -xf ${INSTALLER}
    rm ${INSTALLER}
    echo -e '[Desktop Entry]\nName=Webots\nComment=Webots mobile robot simulator\nExec=/home/will/Documents/webots/webots\nIcon=/home/will/Documents/webots/resources/icons/core/webots.png\nTerminal=false\nType=Application' > ~/.local/share/applications/webots.desktop
    echo 'export WEBOTS_HOME=/home/username/webots' >> ~/.bashrc
    source ~/.bashrc
    set +e; sudo apt-get update; set -e
    sudo apt-get install -y ffmpeg libavcodec-extra ubuntu-restricted-extras libxerces-c-dev libfox-1.6-dev libgdal-dev libproj-dev libgl2ps-dev
    if [[ ! -n $(find ~/ -type d -iname *conda* -maxdepth 1 -print -quit 2>/dev/null) ]]; then
      wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
      chmod +x Miniconda3-latest-Linux-x86_64.sh
      ./Miniconda3-latest-Linux-x86_64.sh
      rm Miniconda3-latest-Linux-x86_64.sh
    fi
    conda install -y x264 ffmpeg -c conda-forge
  elif [[ "$OSTYPE" = "darwin"* ]]; then
    open ${INSTALLER}
  fi # Windows later; too messy
fi

echo "Everything installed. Please close and reopen your terminal to finalize the installation." # source ~/.bashrc doesn't export in here
