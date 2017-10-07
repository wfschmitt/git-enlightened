#!/bin/bash

# ** WORK IN PROGRESS – YOU USE THIS SCRIPT AT YOUR OWN RISK! **

# ONEARTFUL.SH
# ------------

# This script allows you to safely and easily download, install, update the
# GIT master version of Enlightenment 0.22 (aka E22) on Ubuntu Xenial Xerus
# and Artful Aardvark; or helps you perform a clean uninstall of E22 GIT.

# To execute the script:
# 1. Open Terminal (uncheck "Limit scrollback to" in Profile Preferences)
# 2. Change to the folder containing this script
# 3. Make the script executable with chmod +x
# 4. Run it with ./oneartful.sh

# Please note that oneartful.sh is not intended for use inside containers
# (but should run just fine in an Ubuntu VM inside VirtualBox).

# WARNING:
# Enlightenment programs installed from .deb packages (or tarballs) will
# inevitably conflict with E22 programs compiled from GIT source code,
# do not mix source code with pre-built binaries!
# Please remove thoroughly any previous installation of EFL/Enlightenment
# (track down and delete any leftover files) before running my script.

#~ Once installed, you can update your Enlightenment Desktop whenever you
#~ want to——I do this on a daily basis. However, because software gains
#~ entropy over time, I highly recommend doing a complete uninstall
#~ (you may want to keep the hidden ccache folder)
#~ and reinstall of E22 every three weeks or so
#~ for an optimal user experience.

# ONEARTFUL is written by batden@sfr.fr, feel free to use this script
# as you see fit.

# Please consider sending me a tip via https://www.paypal.me/PJGuillaumie
# Cheers!

# LOCAL VARIABLES
# ---------------

#~ Script debugging.
#~ export PS4='+ $LINENO: '
#~ export LC_ALL=C
#~ set -vx

BLD="\e[1m"    # (Bold text)
BRN="\e[0;31m" # (Brown text)
BDR="\e[1;31m" # (Bold red text)
BDG="\e[1;32m" # (Bold green text)
BDY="\e[1;33m" # (Bold yellow text)
BDP="\e[0;35m" # (Bold purple text)
OFF="\e[0m"    # (Turn off ansi colors)

PREFIX=/usr/local
E22="$HOME/enlightenment22"
WTITLE="wmctrl -r :ACTIVE: -N"
GEN="./autogen.sh --prefix=$PREFIX"
SMIL="sudo make install"
RELEASE=$(lsb_release -sc)
DISTRIBUTOR=$(lsb_release -i | cut -f2)
CODE=${LANG:0:2}
GHUB="https://raw.githubusercontent.com/batden/git-enlightened/master"
VER_ONLINE=$(wget --quiet -S -O - $GHUB/14 |& sed '$!d')
CURVERNUM="0.9"

# Folder names lookup.
DOCUDIR=$(test -f ${XDG_CONFIG_HOME:-~/.config}/user-dirs.dirs && \
source ${XDG_CONFIG_HOME:-~/.config}/user-dirs.dirs
echo ${XDG_DOCUMENTS_DIR:-$HOME})

DEPS_EN="aspell-$CODE manpages imagemagick xserver-xephyr \
manpages-dev automake autopoint build-essential ccache \
check cowsay doxygen faenza-icon-theme git \
libasound2-dev libblkid-dev libbluetooth-dev libbullet-dev \
libcogl-gles2-dev libexif-dev libfontconfig1-dev libfreetype6-dev \
libfribidi-dev libgif-dev libgstreamer1.0-dev \
libgstreamer-plugins-base1.0-dev libharfbuzz-dev libibus-1.0-dev \
libiconv-hook-dev libjpeg-dev libblkid-dev libluajit-5.1-dev \
liblz4-dev libmount-dev libpam0g-dev libpoppler-cpp-dev \
libpoppler-dev libpoppler-private-dev libproxy-dev libpulse-dev \
libraw-dev librsvg2-dev libscim-dev libsndfile1-dev libspectre-dev \
libssl-dev libsystemd-dev libtiff5-dev libtool libudev-dev \
libudisks2-dev libunibreak-dev libunwind-dev libvlc-dev \
libwebp-dev libxcb-keysyms1-dev libxcursor-dev libxine2-dev \
libxinerama-dev libxkbfile-dev libxrandr-dev libxss-dev \
libxtst-dev linux-tools-common texlive-base \
unity-greeter-badges valgrind wmctrl"

TRIM_EN=${DEPS_EN:46}

DEPS="aspell-$CODE manpages.$CODE imagemagick xserver-xephyr \
manpages-dev manpages-$CODE-dev manpages-$CODE-extra automake \
autopoint build-essential ccache check cowsay doxygen \
faenza-icon-theme git libasound2-dev libblkid-dev \
libbluetooth-dev libbullet-dev libcogl-gles2-dev libexif-dev \
libfontconfig1-dev libfreetype6-dev libfribidi-dev libgif-dev \
libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
libharfbuzz-dev libibus-1.0-dev libiconv-hook-dev libjpeg-dev \
libblkid-dev libluajit-5.1-dev liblz4-dev libmount-dev libpam0g-dev \
libpoppler-cpp-dev libpoppler-dev libpoppler-private-dev \
libproxy-dev libpulse-dev libraw-dev librsvg2-dev libscim-dev \
libsndfile1-dev libspectre-dev libssl-dev libsystemd-dev \
libtiff5-dev libtool libudev-dev libudisks2-dev libunibreak-dev \
libunwind-dev libvlc-dev libwebp-dev libxcb-keysyms1-dev \
libxcursor-dev libxine2-dev libxinerama-dev libxkbfile-dev \
libxrandr-dev libxss-dev libxtst-dev linux-tools-common \
unity-greeter-badges texlive-base valgrind wmctrl"

TRIM=${DEPS:48}

CLONEFL="git clone https://git.enlightenment.org/core/efl.git"
CLONETY="git clone https://git.enlightenment.org/apps/terminology.git"
CLONE22="git clone https://git.enlightenment.org/core/enlightenment.git"
CLONEPH="git clone https://git.enlightenment.org/apps/ephoto.git"
CLONERG="git clone https://git.enlightenment.org/apps/rage.git"
PROG_AT="efl terminology"
PROG_MN="enlightenment ephoto rage"

# FUNCTIONS
# ---------

sel_menu () {
  if [ $INPUT -lt 1 ]; then
    printf "\n$BDG%s %s\n\n" "1. Install Enlightenment 22."
    printf "$BDG%s $OFF%s\n\n" "2. Update my E22 installation."
    printf "$BRN%s %s\n\n" "3. Uninstall E22 programs."
    printf "$BRN%s $OFF%s\n\n" "4. Remove binary dependencies."

    sleep 1 && printf "$BLD%s $OFF%s\n\n" "—  Or press Ctrl-C to quit."
    read INPUT
  fi
}

bin_deps ()  {
  sudo apt-get update && sudo apt-get dist-upgrade --yes

  if [ $RELEASE == artful ]; then
    sudo apt-get install --yes libopenjp2-7-dev
  fi

  if [ ! -f $DOCUDIR/installed.txt ]; then
    dpkg --get-selections >    $DOCUDIR/installed.txt
    sed -i '/linux-generic*/d' $DOCUDIR/installed.txt
    sed -i '/linux-headers*/d' $DOCUDIR/installed.txt
    sed -i '/linux-image*/d'   $DOCUDIR/installed.txt
    sed -i '/linux-signed*/d'  $DOCUDIR/installed.txt
    sed -i '/linux-tools*/d'   $DOCUDIR/installed.txt
  fi

  if [ $CODE == en ]; then
    sudo apt-get install --yes $DEPS_EN
    if [ $? -ne 0 ]; then
      printf "\n$BDR%s %s\n" "CONFLICTING OR MISSING .DEB PACKAGES."
      printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
      exit 1
    fi
  else
    sudo apt-get install --yes $DEPS
    if [ $? -ne 0 ]; then
      printf "\n$BDR%s %s\n" "CONFLICTING OR MISSING .DEB PACKAGES."
      printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
      exit 1
    fi
  fi
}

ls_ppa () {
  PPA=$(awk '$1 == "Package:" { print $2 }' /var/lib/apt/lists/*ppa*Packages)

  for I in $(echo $PPA | xargs -n1 | sort -u); do
    dpkg-query -Wf'${db:Status-abbrev}' $I &>/dev/null
    if [ $? == 0 ]; then
      # (Packages installed from PPAs are excluded)
      sed -i '/$I/d' $DOCUDIR/installed.txt
    fi
  done
}

ls_dir () {
  COUNT=$(ls -d */ | wc -l)

  if [ $COUNT == 5 ]; then
    printf "$BDG%s $OFF%s\n\n" "All programs have been downloaded successfully."
    sleep 2
  elif [ $COUNT == 0 ]; then
    printf "\n$BDR%s %s\n" "OOPS! SOMETHING WENT WRONG."
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    exit 1
  else
    printf "\n$BDY%s $OFF%s\n\n" "WARNING: ONLY $COUNT OF 5 PROGRAMS HAVE BEEN DOWNLOADED."
    sleep 6
  fi
}

build_def () {
  for I in $PROG_AT; do
    $WTITLE "Processing ${I^} . . ."
    cd $E22/$I
    printf "\n$BLD%s $OFF%s\n\n" "Building $I..."
    case $I in
      efl)
      $GEN --enable-harfbuzz --enable-image-loader-webp
      ;;
      *)
      $GEN
      ;;
    esac
    make
    if [ $? -ne 0 ]; then
      printf "\n$BDR%s $OFF%s\n\n" "BUILD ERROR——TRY AGAIN LATER."
      rm -rf $E22/$I
      exit 1
    fi
    $SMIL
    sudo ldconfig
  done

  for I in $PROG_MN; do
    $WTITLE "Processing ${I^} . . ."
    cd $E22/$I
    printf "\n$BLD%s $OFF%s\n\n" "Building $I..."
    meson . build
    ninja -C build
    if [ $? -ne 0 ]; then
      printf "\n$BDR%s $OFF%s\n\n" "BUILD ERROR——TRY AGAIN LATER."
      rm -rf $E22/$I
      exit 1
    fi
    sudo ninja -C build install
  done
}

rebuild_def () {
  for I in $PROG_AT; do
    $WTITLE "Processing ${I^} . . ."
    cd $E22/$I
    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    make distclean &>/dev/null
    git reset --hard &>/dev/null
    git pull
    case $I in
      efl)
      $GEN --enable-harfbuzz --enable-image-loader-webp
      ;;
      *)
      $GEN
      ;;
    esac
    make
    if [ $? -ne 0 ]; then
      printf "\n$BDR%s $OFF%s\n\n" "BUILD ERROR——TRY AGAIN LATER."
      exit 1
    fi
    $SMIL
    sudo ldconfig
  done

  for I in $PROG_MN; do
    $WTITLE "Processing ${I^} . . ."
    cd $E22/$I
    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    git reset --hard &>/dev/null
    git pull
    rm -rf build/
    meson . build
    ninja -C build
    if [ $? -ne 0 ]; then
      printf "\n$BDR%s $OFF%s\n\n" "BUILD ERROR——TRY AGAIN LATER."
      exit 1
    fi
    sudo ninja -C build install
  done
}

do_tests () {
  if [ -x /usr/bin/wmctrl ]; then
    wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz
  fi

  printf "\n\n$BLD%s $OFF%s\n" "SCANNING SYSTEM AND GIT REPOSITORIES..."
  sleep 1

  if [ $RELEASE == artful ] || [ $RELEASE == xenial ]; then
    printf "\n$BDG%s $OFF%s\n\n" "Ubuntu ${RELEASE^}... OK"
    sleep 1
  else
    printf "\n$BDR%s $OFF%s\n\n" "UNSUPPORTED OPERATING SYSTEM."
    exit 1
  fi

  dpkg -l | egrep -w 'e17|e20|enlightenment' &>/dev/null
  if [ $? == 0 ]; then
    printf "\n$BDR%s %s\n" "ANOTHER VERSION OF ENLIGHTENMENT IS ALREADY INSTALLED AND"
    printf "\n$BDR%s %s\n" "THESE TWO VERSIONS ARE NOT COMPATIBLE WITH EACH OTHER."
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    exit 1
  fi

  if [ "$(pidof enlightenment)" ]; then
    printf "\n$BDR%s $OFF%s\n\n" "PLEASE LOG IN TO ${DISTRIBUTOR^^} TO EXECUTE THIS SCRIPT."
    exit 1
  fi

  ping -c 2 git.enlightenment.org &>/dev/null
  if [ $? -ne 0 ]; then
    printf "\n$BDR%s %s\n" "REMOTE HOST IS UNREACHABLE——TRY AGAIN LATER"
    printf "$BDR%s $OFF%s\n\n" "OR VERIFY YOUR NETWORK CONNECTION."
    exit 1
  fi
}

do_bsh_alias () {
  if [ ! -f $HOME/.bash_aliases ]; then
    touch $HOME/.bash_aliases

  cat > $HOME/.bash_aliases << `EOF`

  # ONEARTFUL.SH ADDITIONS
  # ----------------------

  # Simple shortcut.
  alias go='cd $HOME/git-enlightened'

  # Compiler and linker flags.
  export CC="ccache gcc"
  export CXX="ccache g++"
  export USE_CCACHE=1
  export CCACHE_COMPRESS=1
  export CPPFLAGS=-I/usr/local/include
  export LDFLAGS=-L/usr/local/lib
  export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

  # Enable parallel build.
  # (Comment out the following line if you get build errors with other projects)
  export MAKE="make -j$(($(getconf _NPROCESSORS_ONLN)*2))"

  # Set the PATH environment variable (if necessary).
`EOF`

  source $HOME/.bash_aliases
  fi
}

get_meson () {
  which meson &>/dev/null
  if [ "$?" -ne 0 ]; then
    sudo apt-get install ninja-build python3-pip
  fi

  pip3 install --user meson
  if [ "$?" == 0 ]; then
    if ! echo $PATH | grep -q $HOME/.local/bin; then
      echo -e '  export PATH=$HOME/.local/bin:$PATH' >> $HOME/.bash_aliases
      source $HOME/.bash_aliases
    fi
  else
    printf "\n$BDR%s %s\n" "OOPS! SOMETHING WENT WRONG."
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    exit 1
  fi
}

install_go () {
  clear; printf "\n$BDG%s $OFF%s\n\n" "* PROCEEDING TO INSTALL ENLIGHTENMENT 22 *"
  do_bsh_alias

  if grep -q ppa /var/lib/apt/lists/*ppa* &>/dev/null; then
    bin_deps
    ls_ppa
  else
    unset -f ls_ppa
    bin_deps
  fi

  get_meson

  cd $HOME; mkdir -p $E22; cd $E22

  $WTITLE "Downloading Source Code . . ."
  printf "\n\n$BLD%s $OFF%s\n\n" "Fetching git code..."
  $CLONEFL; echo
  $CLONETY; echo
  $CLONE22; echo
  $CLONEPH; echo
  $CLONERG; echo

  ls_dir

  $WTITLE "Processing Enlightenment Programs . . ."
  build_def

  $WTITLE "Finalizing Installation . . ."
  printf "\n%s\n\n" "Almost done..."

  mkdir -p $HOME/.elementary/themes/

  sudo ln -sf \
  /usr/local/share/dbus-1/services/org.enlightenment.Ethumb.service \
  /usr/share/dbus-1/services/org.enlightenment.Ethumb.service

  sudo ln -sf /usr/local/share/xsessions/enlightenment.desktop \
  /usr/share/xsessions/enlightenment.desktop

  sudo updatedb
  $WTITLE "Installation Complete."
  printf "\n\n$BDY%s %s" "Enlightenment first time wizard tips:"
  printf "\n$BDY%s %s" "Update checking——You can disable this feature because it serves no useful purpose."
  printf "\n$BDY%s $OFF%s\n\n\n" "Network management support——Do NOT install Connman!"

  if [ $RELEASE == artful ]; then
    echo; cowsay "Now reboot your computer then select Enlightenment on the login screen... That's All Folks!"; echo
  else
    echo; cowsay "No Reboot Required... That's All Folks!"; echo
  fi
}

update_go () {
  clear; printf "\n$BDG%s $OFF%s\n\n" "* PROCEEDING TO UPDATE ENLIGHTENMENT 22 *"
  sleep 1

  printf "\n$BLD%s $OFF%s\n\n" "Satisfying dependencies under Ubuntu ${RELEASE^}..."
  if [ $CODE == en ]; then
    sudo apt-get install --yes $DEPS_EN
    sleep 1
  else
    sudo apt-get install --yes $DEPS
    sleep 1
  fi

  $WTITLE "Processing Enlightenment Programs . . ."
  rebuild_def

  sudo updatedb
  $WTITLE "Update Complete."
  echo; cowsay -f www "That's All Folks!"; echo
}

remov_eprog_at () {
  for I in $PROG_AT; do
    sudo make uninstall &>/dev/null
    make maintainer-clean &>/dev/null
  done
}

remov_eprog_mn () {
  for I in $PROG_MN; do
    sudo ninja -C build uninstall &>/dev/null
    rm -rf build &>/dev/null
  done
}

uninstall_main_deps () {
  clear; echo; read -t 3 -p "Wait 3s or hit Ctrl-C to abort..."

  $WTITLE "Processing Ubuntu Packages . . ."
  echo; printf "\n$BRN%s $OFF%s\n\n" "* Removing binary dependencies... *"

  #~ (Think twice before proceeding with the removal of these packages!
  #~  If you're in doubt, take a screenshot first for future reference)
  if [ $CODE == en ]; then
    sudo apt-get autoremove $TRIM_EN
    sleep 1
  else
    sudo apt-get autoremove $TRIM
    sleep 1
  fi

  sudo dpkg --set-selections < $DOCUDIR/installed.txt
  sudo apt-get dselect-upgrade
  sudo apt-get update
  sudo apt-get dist-upgrade

  cd $HOME; echo
  rm $DOCUDIR/installed.txt &>/dev/null

  sudo apt-get autoremove --purge
  sudo dpkg --purge $(COLUMNS=200 dpkg -l | grep "^rc" | tr -s ' ' | \
  cut -d ' ' -f 2) &>/dev/null

  if [ $RELEASE == artful ]; then
    sudo apt-get autoremove --yes libopenjp2-7-dev &>/dev/null
  fi

  printf "\n%s\n\n" "[Output of ubuntu-support-status]"
  ubuntu-support-status; echo
}

uninstall_e22 () {
  clear; echo; read -t 3 -p "Wait 3s or hit Ctrl-C to abort..."

  printf "\n\n$BRN%s %s\n" "* Proceeding to uninstall Enlightenment 22 *"
  printf "$BRN%s $OFF%s\n\n" "* Please be patient... *"

  for I in $PROG_AT; do
    cd $E22/$I && remov_eprog_at
  done

  for I in $PROG_MN; do
    cd $E22/$I && remov_eprog_mn
  done

  cd $HOME
  rm -rf enlightenment22/
  rm -rf .e/
  rm -rf .elementary/
  rm -rf .cache/efreet/
  rm -rf .cache/ephoto/
  rm -rf .cache/evas_gl_common_caches/
  rm -rf .cache/rage/
  rm -rf .config/ephoto/
  rm -rf .config/rage/
  rm -rf .config/terminology/

  cd /usr/local/etc/
  sudo rm -rf enlightenment/

  cd /usr/local/include/
  sudo rm -rf *-1
  sudo rm -rf enlightenment/

  cd /usr/local/lib/
  sudo rm -rf ecore*
  sudo rm -rf edje*
  sudo rm -rf eeze*
  sudo rm -rf efl*
  sudo rm -rf efreet*
  sudo rm -rf elementary*
  sudo rm -rf emotion*
  sudo rm -rf ethumb*
  sudo rm -rf evas*
  sudo rm -rf x86*

  cd /usr/local/lib/cmake/
  sudo rm -rf Ecore*
  sudo rm -rf Edje*
  sudo rm -rf Eet*
  sudo rm -rf Eeze*
  sudo rm -rf Efl*
  sudo rm -rf Efreet*
  sudo rm -rf Eina*
  sudo rm -rf Eio*
  sudo rm -rf Eldbus*
  sudo rm -rf Elementary*
  sudo rm -rf Elua*
  sudo rm -rf Emile*
  sudo rm -rf Emotion*
  sudo rm -rf Eo*
  sudo rm -rf Ethumb*
  sudo rm -rf Evas*

  cd /usr/local/share/
  sudo rm -rf dbus*
  sudo rm -rf ecore*
  sudo rm -rf edje*
  sudo rm -rf eeze*
  sudo rm -rf efreet*
  sudo rm -rf elementary*
  sudo rm -rf elua*
  sudo rm -rf embryo*
  sudo rm -rf emotion*
  sudo rm -rf enlightenment*
  sudo rm -rf eo*
  sudo rm -rf eolian*
  sudo rm -rf ephoto*
  sudo rm -rf ethumb*
  sudo rm -rf evas*
  sudo rm -rf rage*
  sudo rm -rf terminology*

  cd /usr/local/share/applications/
  sudo sed -i '/enlightenment_filemanager/d' mimeinfo.cache
  sudo sed -i '/ephoto/d' mimeinfo.cache
  sudo sed -i '/rage/d' mimeinfo.cache

  cd /usr/local/share/icons/
  sudo rm -rf Enlightenment-X/

  cd /usr/share/
  sudo rm -rf xsessions/enlightenment.desktop
  cd /usr/share/dbus-1/services/
  sudo rm -rf org.enlightenment.Ethumb.service

  cd $HOME

  find /usr/local/share/locale/*/LC_MESSAGES/ 2>/dev/null | while read -r I; do
    if [ -f "$I/efl.mo" ]; then
      cd "$I" && sudo rm -rf efl*
    fi
  done

  find /usr/local/share/locale/*/LC_MESSAGES/ 2>/dev/null | while read -r I; do
    if [ -f "$I/enlightenment.mo" ]; then
      cd "$I" && sudo rm -rf enlightenment*
    fi
  done

  find /usr/local/share/locale/*/LC_MESSAGES/ 2>/dev/null | while read -r I; do
    if [ -f "$I/ephoto.mo" ]; then
      cd "$I" && sudo rm -rf ephoto*
    fi
  done

  find /usr/local/share/locale/*/LC_MESSAGES/ 2>/dev/null | while read -r I; do
    if [ -f "$I/terminology.mo" ]; then
      cd "$I" && sudo rm -rf terminology*
    fi
  done

  if [ -d $HOME/.ccache/ ]; then
    read -t 10 -p "Remove the hidden ccache folder (compiler cache)? [y/N] " answer
    case $answer in
      [yY] )
      rm -rf $HOME/.ccache/
      ;;
      [nN] )
      printf "\n%s\n\n" "(Do not delete the ccache folder... OK)"
      ;;
      *    )
      echo; printf "\n%s\n\n" "(Do not delete the ccache folder... OK)"
      ;;
    esac
  fi

  if [ -f $HOME/.bash_aliases ]; then
    read -t 10 -p "Remove the hidden bash_aliases file? [y/N] " answer
    case $answer in
      [yY] )
      rm -rf $HOME/.bash_aliases
      source $HOME/.bashrc
      ;;
      [nN] )
      printf "\n%s\n\n" "(Do not delete bash_aliases... OK)"
      ;;
      *    )
      echo; printf "\n%s\n\n" "(Do not delete bash_aliases... OK)"
      ;;
    esac
  fi

  if [ -d $HOME/git-enlightened/ ]; then
    rm -rf $HOME/git-enlightened/
  fi

  sudo updatedb
  echo; cowsay -d "That's All Folks!"; echo
}

main () {
  trap '{ printf "\n$BDR%s $OFF%s\n\n" "KEYBOARD INTERRUPT."; exit 130; }' INT

  printf "\n%s\n" "$VER_ONLINE"
  printf "%s\n" "[You are currently using v$CURVERNUM]"
  sleep 3

  do_tests

  INPUT=0
  printf "\n$BLD%s $OFF%s\n" "Please enter the number of your choice:"
  sel_menu

  if   [ $INPUT == 1 ]; then
    install_go
  elif [ $INPUT == 2 ]; then
    update_go
  elif [ $INPUT == 3 ]; then
    uninstall_e22
  elif [ $INPUT == 4 ]; then
    uninstall_main_deps
  else
    exit 1
  fi
}

main
