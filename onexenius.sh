#!/bin/bash

#~#~# ONEXENIUS.SH

#~ This script allows you to safely and easily download, install, update the
#~ GIT master version of Enlightenment 0.22 (aka E22) on Ubuntu Xenial Xerus
#~ and Zesty Zapus; or helps you perform a clean uninstall of E22 GIT.

#~ To execute the script:
#~ 1. Open Terminal (uncheck "Limit scrollback to" in Profile Preferences)
#~ 2. Change to the folder containing this script
#~ 3. Make the script executable with chmod +x
#~ 4. Run it with ./onexenius.sh

#~ Please note that onexenius.sh is not intended for use inside containers
#~ (but should run just fine in an Ubuntu VM inside VirtualBox).

#~ WARNING:
#~ Enlightenment programs installed from .deb packages (or tarballs) will
#~ inevitably conflict with E22 programs compiled from GIT source code,
#~ do not mix source code with precompiled binaries!
#~ Please remove thoroughly any previous installation of EFL/Enlightenment
#~ (track down and delete any leftover files) before running my script.

#~ Once installed, you can update your Enlightenment Desktop whenever you
#~ want to——I do this on a daily basis. However, because software gains
#~ entropy over time, I highly recommend doing a complete uninstall
#~ (you may want to keep the hidden ccache folder)
#~ and reinstall of E22 every three weeks or so
#~ for an optimal user experience.

#~ ONEXENIUS is written by batden@sfr.fr, feel free to use this script
#~ as you see fit.

#~ Please consider sending me a tip via https://www.paypal.me/PJGuillaumie
#~ Cheers!

#~#~# VARIABLES

#~ (Script debugging)
#~ export PS4='+ $LINENO: '
#~ export LC_ALL=C
#~ set -vx

PREFIX=/usr/local
E22="$HOME/Enlightenment22"
TITLE="wmctrl -r :ACTIVE: -N"
GEN="./autogen.sh --prefix=$PREFIX"
SMIL="sudo make install"
RELEASE=$(lsb_release -sc)
DISTRIBUTOR=$(lsb_release -i | cut -f2)
CODE=${LANG:0:2}
GHUB="https://raw.githubusercontent.com/batden/git-enlightened/master"
VER_ONLINE=$(wget --quiet -S -O - $GHUB/14 |& sed '$!d')
CURVERNUM="16.8"

#~ (Color output)
BLD="\e[1m"     #~ (Bold text)
BRN="\e[0;31m"  #~ (Brown text)
BDR="\e[1;31m"  #~ (Bold red text)
BDG="\e[1;32m"  #~ (Bold green text)
BDY="\e[1;33m"  #~ (Bold yellow text)
BDP="\e[0;35m"  #~ (Bold purple text)
OFF="\e[0m"     #~ (Turn off ansi colors)

#~ (Compiler and linker flags)
export CC="ccache gcc"
export CXX="ccache g++"
export USE_CCACHE=1
export CCACHE_COMPRESS=1
export CPPFLAGS=-I/usr/local/include
export LDFLAGS=-L/usr/local/lib
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

#~ (Load balancing for multi-core systems)
export MAKE="make -j$(($(getconf _NPROCESSORS_ONLN)*2))"

#~ (Folder names lookup)
DOCUDIR=$(test -f ${XDG_CONFIG_HOME:-~/.config}/user-dirs.dirs && \
source ${XDG_CONFIG_HOME:-~/.config}/user-dirs.dirs
echo ${XDG_DOCUMENTS_DIR:-$HOME})

DEPS_EN="aspell-$CODE manpages imagemagick xserver-xephyr \
manpages-dev automake autopoint build-essential ccache \
check cowsay doxygen faenza-icon-theme git \
libasound2-dev libblkid-dev libbluetooth-dev libbullet-dev \
libcogl-dev libfontconfig1-dev libfreetype6-dev libfribidi-dev \
libgif-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
libharfbuzz-dev libibus-1.0-dev libiconv-hook-dev libjpeg-dev \
libblkid-dev libluajit-5.1-dev liblz4-dev libmount-dev \
libpam0g-dev libpoppler-cpp-dev libpoppler-dev \
libpoppler-private-dev libproxy-dev libpulse-dev libraw-dev \
librsvg2-dev libscim-dev libsndfile1-dev libspectre-dev \
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
libbluetooth-dev libbullet-dev libcogl-dev libfontconfig1-dev \
libfreetype6-dev libfribidi-dev libgif-dev libgstreamer1.0-dev \
libgstreamer-plugins-base1.0-dev libharfbuzz-dev libibus-1.0-dev \
libiconv-hook-dev libjpeg-dev libblkid-dev libluajit-5.1-dev \
liblz4-dev libmount-dev libpam0g-dev libpoppler-cpp-dev \
libpoppler-dev libpoppler-private-dev libproxy-dev libpulse-dev \
libraw-dev librsvg2-dev libscim-dev libsndfile1-dev \
libspectre-dev libssl-dev libsystemd-dev libtiff5-dev libtool \
libudev-dev libudisks2-dev libunibreak-dev libunwind-dev \
libvlc-dev libwebp-dev libxcb-keysyms1-dev libxcursor-dev \
libxine2-dev libxinerama-dev libxkbfile-dev libxrandr-dev \
libxss-dev libxtst-dev linux-tools-common \
unity-greeter-badges texlive-base valgrind wmctrl"

TRIM=${DEPS:48}

CLONEFL="git clone https://git.enlightenment.org/core/efl.git"
CLONE22="git clone https://git.enlightenment.org/core/enlightenment.git"
CLONETY="git clone https://git.enlightenment.org/apps/terminology.git"
EPROGRM="efl enlightenment terminology"

#~#~# FUNCTIONS

leftover_detect () {
if [ -d $HOME/.e/ -o -d $HOME/.elementary/ ]; then
    printf "\n$BDY%s %s\n" "
That's weird, configuration files from a previous install of EFL/E"
    printf "$BDY%s $OFF%s\n\n" "are still present in your home folder..."

    read -t 10 -p "Do you want to remove these files? [Y/n] " answer
    case $answer in
      [yY] )
        rm -rf $HOME/.e/ &>/dev/null
        rm -rf $HOME/.elementary/ &>/dev/null
        rm -rf $HOME/.cache/efreet/ &>/dev/null
        rm -rf $HOME/.cache/evas/ &>/dev/null
        rm -rf $HOME/.cache/evas_gl_common_caches/ &>/dev/null
        rm -rf $HOME/.config/terminology/ &>/dev/null
        ;;
      [nN] )
        printf "\n%s\n\n" "(Do not delete the config folders... OK)"
        ;;
      *    )
        rm -rf $HOME/.e/ &>/dev/null
        rm -rf $HOME/.elementary/ &>/dev/null
        rm -rf $HOME/.cache/efreet/ &>/dev/null
        rm -rf $HOME/.cache/evas/ &>/dev/null
        rm -rf $HOME/.cache/evas_gl_common_caches/ &>/dev/null
        rm -rf $HOME/.config/terminology/ &>/dev/null
        ;;
    esac
fi
}

zen_warn () {
zenity --no-wrap --info --text "
This installation will take up about 1.5 GB of space.\n
Keep in mind that running other applications\n\
during the build process will affect\n\
compilation time.\n"
}

sel_menu () {
if [ $INPUT -lt 1 ]; then
    printf "\n$BDG%s $OFF%s\n\n" "1. Install Enlightenment 22." #~ (Standard)
    printf "$BDG%s %s\n\n" "2. Update my E22 installation." #~ (Standard)
    printf "$BRN%s %s\n\n" "3. Uninstall E22 programs only."
    printf "$BRN%s $OFF%s\n" "4. Uninstall E22 programs AND \
binary dependencies."
    printf "$BDY%s %s\n" "
5. Update and rebuild E22 for debugging" #~ (Slower——Not suitable for daily use)
    printf "$BDY%s %s\n" "   (Make sure default E theme is applied)."
    printf "$BDY%s %s\n" "
6. Update and rebuild E22 with optimizations enabled" #~ (Run faster)
    printf "$BDY%s $OFF%s\n\n" "   (Tarball generation? \
Answer yes to i18n support)."
    sleep 1 && printf "$BLD%s $OFF%s\n\n" "—  Or press Ctrl-C to quit."
    read INPUT
fi
}

beep_attention () {
which canberra-gtk-play &>/dev/null
if [ $? == 0 ]; then
    canberra-gtk-play --id="window-attention" &>/dev/null
else
    paplay /usr/share/sounds/freedesktop/stereo/dialog-warning.oga
fi
}

beep_question () {
which canberra-gtk-play &>/dev/null
if [ $? == 0 ]; then
    printf "\e[?5h"
    canberra-gtk-play --id="dialog-information" &>/dev/null
    printf "\e[?5l"
else
    printf "\e[?5h"
    paplay /usr/share/sounds/freedesktop/stereo/dialog-information.oga
    printf "\e[?5l"
fi
}

beep_exit () {
which canberra-gtk-play &>/dev/null
if [ $? == 0 ]; then
    canberra-gtk-play --id="suspend-error" &>/dev/null
else
    paplay /usr/share/sounds/freedesktop/stereo/suspend-error.oga
fi   
}

beep_ok () {
which canberra-gtk-play &>/dev/null
if [ $? == 0 ]; then
    canberra-gtk-play --id="complete" &>/dev/null
else
    paplay /usr/share/sounds/freedesktop/stereo/complete.oga
fi
}

bin_deps ()  {
sudo apt-get update && sudo apt-get dist-upgrade --yes

if [ $RELEASE == zesty ]; then
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

#~ (locale-dependent sorting)
if [ $CODE == en ]; then
    sudo apt-get install --yes $DEPS_EN
        if [ $? -ne 0 ]; then
            printf "\n$BDR%s %s\n" " CONFLICTING OR MISSING .DEB PACKAGES."
            printf "$BDR%s $OFF%s\n\n" " SCRIPT ABORTED."
            exit 1
        fi
else
    sudo apt-get install --yes $DEPS
        if [ $? -ne 0 ]; then
            printf "\n$BDR%s %s\n" " CONFLICTING OR MISSING .DEB PACKAGES."
            printf "$BDR%s $OFF%s\n\n" " SCRIPT ABORTED."
            exit 1
        fi
fi
}

ls_ppa () {
PPA=$(awk '$1 == "Package:" { print $2 }' /var/lib/apt/lists/*ppa*Packages)

for I in $(echo $PPA | xargs -n1 | sort -u)
do
    dpkg-query -Wf'${db:Status-abbrev}' $I &>/dev/null
        if [ $? == 0 ]; then
        #~ (Packages installed from PPAs are excluded)
            sed -i '/$I/d' $DOCUDIR/installed.txt
        fi
done
}

ls_dir () {
COUNT=$(ls -d */ | wc -l)

if [ $COUNT == 3 ]; then
    printf "$BDG%s $OFF%s\n\n" "All programs have been downloaded successfully."
    sleep 2
elif [ $COUNT == 0 ]; then
    printf "\n$BDR%s %s\n" " OOPS! SOMETHING WENT WRONG."
    printf "$BDR%s $OFF%s\n\n" " SCRIPT ABORTED."
    exit 1
else
    printf "\n$BDY%s $OFF%s\n\n" "
 WARNING: ONLY $COUNT OF 3 PROGRAMS HAVE BEEN DOWNLOADED."
    sleep 6
fi
}

err_shot () {
which gnome-screenshot &>/dev/null
if [ $? == 0 ]; then
    gnome-screenshot -d 1 &>/dev/null
else
    xfce4-screenshooter -w -d 1 &>/dev/null || spectacle -d 1 &>/dev/null
fi
}

e_bak () {
TSTAMP=$(date +%s)
mkdir -p $HOME/Dropbox/Enlight22/
mkdir $HOME/Dropbox/Enlight22/E_$TSTAMP
cp -aR $HOME/.elementary $HOME/Dropbox/Enlight22/E_$TSTAMP
cp -aR $HOME/.e $HOME/Dropbox/Enlight22/E_$TSTAMP
sleep 2
#~ (Timestamp: See the date man page to convert epoch to human readable date)
}

dpbx_detect () {
if [ "$(pidof dropbox)" ]; then
    printf "$BDG%s $OFF%s\n" "DROPBOX is running on this computer..."
    beep_question; read -t 10 -p "
Do you want to back up your E22 settings to your Dropbox now? [y/N] " answer
    case $answer in
      [yY] )
        e_bak; echo
        ;;
      [nN] )
        printf "%s\n\n" "
(Do not back up my user settings and themes folders... OK)"
        ;;
      *    )
        echo; printf "%s\n\n" "
(Do not back up my user settings and themes folders... OK)"
        ;;
    esac
fi
}

build_std () {
for I in $EPROGRM
do
    $TITLE "Processing ${I^} . . ."
    cd $E22/$I
    printf "\n$BLD%s $OFF%s\n\n" "Building $I..."

    #~ (Configure)
        case $I in
          efl)
            $GEN --enable-cxx-bindings --enable-harfbuzz \
            --enable-image-loader-webp --enable-multisense \
            --enable-systemd --enable-xine --enable-xinput22
            ;;
          enlightenment)
            $GEN --enable-mount-eeze --disable-geolocation \
            --disable-wl-desktop-shell
            ;;
          *) 
            $GEN
            ;;
        esac

    #~ (Build)
        echo
        $TITLE "Processing ${I^} . . ."
        make
            if [ $? -ne 0 ]; then
                printf "\n$BDR%s $OFF%s\n\n" " BUILD ERROR——TRY AGAIN LATER."
                #~ (Relaunch the script at a later time and select option #1)
                err_shot
                rm -rf $E22/$I
                beep_exit
                exit 1
            fi

    #~ (Uncomment the line below to run the self-tests)
    #~echo; make -k check; echo

    #~ (Install)
        $TITLE "Processing ${I^} . . ."
        case $I in
          efl)
            beep_attention; $SMIL
            ;;
          *)
            $SMIL
            ;;
        esac

    sudo ldconfig
    logger -i "onexenius.sh: Enlightenment 22 was successfully installed."
    echo
done
}

build_no_nls () {
for I in $EPROGRM
do
    $TITLE "Processing ${I^} . . ."
    cd $E22/$I
    printf "\n$BDP%s $OFF%s\n\n" "Building $I..."

    #~ (Configure)
        case $I in
          efl)
            $GEN --enable-cxx-bindings --enable-image-loader-webp \
            --enable-multisense --enable-systemd --enable-xine \
            --enable-xinput22 --disable-harfbuzz --disable-nls
            ;;
          enlightenment)
            $GEN --enable-mount-eeze --disable-geolocation \
            --disable-nls --disable-wl-desktop-shell
            ;;
          terminology)
            $GEN --disable-nls
            ;;
          *)
            $GEN
            ;;
        esac

    #~ (Build)
        echo
        $TITLE "Processing ${I^} . . ."
        make
            if [ $? -ne 0 ]; then
                printf "\n$BDR%s $OFF%s\n\n" " BUILD ERROR——TRY AGAIN LATER."
                #~ (Relaunch the script at a later time and select option #1)
                err_shot
                rm -rf $E22/$I
                beep_exit
                exit 1
            fi

    #~ (Install)
        $TITLE "Processing ${I^} . . ."
        case $I in
          efl)
            beep_attention; $SMIL
            ;;
          *) 
            $SMIL
            ;;
        esac

    sudo ldconfig
    logger -i "onexenius.sh: Enlightenment 22 was successfully installed."
    echo
done
}

rebuild_std () {
for I in $EPROGRM
do
    $TITLE "Processing ${I^} . . ."
    cd $E22/$I
    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    #~ (Source tree cleanup)
    make distclean &>/dev/null
    git reset --hard &>/dev/null
    #~ (Repository synchronization)
    git pull
    echo
    #~ (Configure)
        case $I in
          efl)
            $GEN --enable-cxx-bindings --enable-harfbuzz \
            --enable-image-loader-webp --enable-multisense \
            --enable-systemd --enable-xine --enable-xinput22 
            ;;
          enlightenment)
            $GEN --enable-mount-eeze --disable-geolocation \
            --disable-wl-desktop-shell
            ;;
          *)
            $GEN
            ;;
        esac
    #~ (Build)
    echo
    $TITLE "Processing ${I^} . . ."
    make
        if [ $? -ne 0 ]; then
            printf "\n$BDR%s $OFF%s\n\n" " BUILD ERROR——TRY AGAIN LATER."
            #~ (Relaunch the script at a later time and select option #2)
            beep_exit
            exit 1
        fi

    #~ (Uncomment the line below to run the self-tests)
    #~echo; make -k check; echo

    #~ (Install)
    $TITLE "Processing ${I^} . . ."
    $SMIL
    sudo ldconfig
    echo
done
}

rebuild_no_nls () {
for I in $EPROGRM
do
    $TITLE "Processing ${I^} . . ."
    cd $E22/$I
    printf "\n$BDP%s $OFF%s\n\n" "Updating $I..."
    #~ (Source tree cleanup)
    make distclean &>/dev/null
    git reset --hard &>/dev/null
    #~ (Repository synchronization)
    git pull
    echo
    #~ (Configure)
        case $I in
          efl)
            $GEN --enable-cxx-bindings --enable-image-loader-webp \
            --enable-multisense --enable-systemd --enable-xine \
            --enable-xinput22 --disable-harfbuzz --disable-nls 
            ;;
          enlightenment)
            $GEN --enable-mount-eeze --disable-geolocation \
            --disable-nls --disable-wl-desktop-shell
            ;;
          terminology)
            $GEN --disable-nls
            ;;
          *)
            $GEN
            ;;
        esac
    #~ (Build)
    echo
    $TITLE "Processing ${I^} . . ."
    make
        if [ $? -ne 0 ]; then
            printf "\n$BDR%s $OFF%s\n\n" " BUILD ERROR——TRY AGAIN LATER."
            #~ (Relaunch the script at a later time and select option #2)
            beep_exit
            exit 1
        fi
    #~ (Install)
    $TITLE "Processing ${I^} . . ."
    $SMIL
    sudo ldconfig
    echo
done
}

rebuild_optim () {
export CFLAGS="-O3 -ffast-math -march=native"
export CXXFLAGS="-O3 -ffast-math -march=native"

for I in $EPROGRM
do
    $TITLE "Processing ${I^} . . ."
    cd $E22/$I
    printf "\n$BDY%s $OFF%s\n\n" "
Rebuilding $I with optimizations and nls support enabled..."
    make distclean &>/dev/null
    git reset --hard; echo
    git pull
    echo
        case $I in
          efl)
            $GEN --enable-cxx-bindings --enable-harfbuzz \
            --enable-image-loader-webp --enable-multisense \
            --enable-systemd --enable-xine --enable-xinput22 \
            --with-profile=release
            ;;
          enlightenment)
            $GEN --enable-mount-eeze --disable-geolocation \
            --disable-wl-desktop-shell --with-profile=FAST_PC
            ;;
          *)
            $GEN
            ;;
        esac
    echo
    $TITLE "Processing ${I^} . . ."
    make
        if [ $? -ne 0 ]; then
            printf "\n$BDR%s $OFF%s\n\n" " BUILD ERROR——TRY AGAIN LATER."
            #~ (Relaunch the script at a later time and select option #6)
            beep_exit
            exit 1
        fi
    sleep 2

    ##~  (BUILD TEST: Uncomment the line below to produce a tarball
    ##~  ——your terminal may appear to be frozen, waiting a few
    ##~  minutes will allow the task to complete)

    #~echo; make dist; echo

    $TITLE "Processing ${I^} . . ."
    $SMIL
    sudo ldconfig
    echo
done
}

rebuild_optim_no_nls () {
export CFLAGS="-O3 -ffast-math -march=native"
export CXXFLAGS="-O3 -ffast-math -march=native"

for I in $EPROGRM
do
    $TITLE "Processing ${I^} . . ."
    cd $E22/$I
    printf "\n$BDP%s $OFF%s\n\n" "Rebuilding $I with optimizations enabled..."
    make distclean &>/dev/null
    git reset --hard; echo
    git pull
    echo
        case $I in
          efl)
            $GEN --enable-cxx-bindings --enable-image-loader-webp \
            --enable-multisense --enable-systemd --enable-xine \
            --enable-xinput22 --disable-harfbuzz --disable-nls \
            --with-profile=release
            ;;
          enlightenment)
            $GEN --enable-mount-eeze --disable-geolocation --disable-nls \
            --disable-wl-desktop-shell --with-profile=FAST_PC
            ;;
          terminology)
            $GEN --disable-nls
            ;;
          *)
            $GEN
            ;;
        esac
    echo
    $TITLE "Processing ${I^} . . ."
    make
        if [ $? -ne 0 ]; then
            printf "\n$BDR%s $OFF%s\n\n" " BUILD ERROR——TRY AGAIN LATER."
            #~ (Relaunch the script at a later time and select option #6)
            beep_exit
            exit 1
        fi
    sleep 2

    $TITLE "Processing ${I^} . . ."
    $SMIL
    sudo ldconfig
    echo
done
}

rebuild_for_debug () {	
export LC_ALL=C
export CFLAGS="-g -ggdb3"
export CXXFLAGS="-g -ggdb3"
#~ (Uncomment the line below to produce a much more detailed output)
#~export EINA_LOG_LEVEL=4

echo

#~ (Temporary tweaks until next reboot)
sudo sysctl -w kernel.yama.ptrace_scope=0
ulimit -c unlimited
echo "/var/crash/core.%e.%p.%h.%t" | sudo tee /proc/sys/kernel/core_pattern

for I in $EPROGRM
do
    $TITLE "Processing ${I^} . . ."
    cd $E22/$I
    printf "\n$BDY%s $OFF%s\n\n" "Rebuilding $I with debug symbols..."
    make distclean; echo
    git reset --hard; echo
    git pull
    echo
        case $I in
          efl)
            $GEN --enable-cxx-bindings --enable-image-loader-webp \
            --enable-multisense --enable-systemd --enable-xine \
            --enable-xinput22 --enable-valgrind --disable-harfbuzz \
            --disable-nls
            ;;
          enlightenment)
            $GEN --enable-mount-eeze --disable-geolocation --disable-nls \
            --disable-wl-desktop-shell
            ;;
          terminology)
            $GEN --disable-nls
            ;;
          *)
            $GEN
            ;;
        esac
    echo
    $TITLE "Processing ${I^} . . ."
    make
        if [ $? -ne 0 ]; then
            printf "\n$BDR%s $OFF%s\n\n" " REBUILD ERROR——TRY AGAIN LATER."
            #~ (Relaunch the script at a later time and select option #5)
            beep_exit
            exit 1
        fi
    $TITLE "Processing ${I^} . . ."
    $SMIL
    sudo ldconfig
    echo
done
}

remove_prgrm () {
case $I in
    efl)
        printf "\n$BLD%s $OFF%s\n\n" "Cleaning $I... Please be patient."
        ;;
    *)
        printf "\n$BLD%s $OFF%s\n\n" "Cleaning $I..."
        ;;
esac

sudo make uninstall &>/dev/null
make maintainer-clean &>/dev/null
echo
}

deep_clean () {
echo; printf "\n$BLD%s $OFF%s\n\n" "Deeper cleaning..."; sleep 1

cd $E22
sudo rm -rf terminology/
sudo rm -rf enlightenment/
sudo rm -rf efl/

cd $HOME
rm -rf Enlightenment22/
rm -rf .e/
rm -rf .elementary/
rm -rf .cache/efreet/
rm -rf .cache/evas_gl_common_caches/
rm -rf .config/terminology/

cd /usr/local/bin/
sudo rm -rf ecore*
sudo rm -rf elementary*
sudo rm -rf emotion_test*

cd /usr/local/etc/
sudo rm -rf enlightenment/

cd /usr/local/include/
sudo rm -rf ecore*
sudo rm -rf ector*
sudo rm -rf edje*
sudo rm -rf eet*
sudo rm -rf eeze*
sudo rm -rf efl*
sudo rm -rf efreet*
sudo rm -rf eina*
sudo rm -rf eio*
sudo rm -rf eldbus*
sudo rm -rf elementary*
sudo rm -rf elocation*
sudo rm -rf elua*
sudo rm -rf embryo*
sudo rm -rf emile*
sudo rm -rf emotion*
sudo rm -rf enlightenment*
sudo rm -rf eo*
sudo rm -rf ephysics*
sudo rm -rf ethumb*
sudo rm -rf evas*

cd /usr/local/lib/
sudo rm -rf ecore*
sudo rm -rf edje*
sudo rm -rf eeze*
sudo rm -rf efl*
sudo rm -rf efreet*
sudo rm -rf elementary*
sudo rm -rf emotion*
sudo rm -rf enlightenment*
sudo rm -rf eo*
sudo rm -rf ephysics*
sudo rm -rf ethumb*
sudo rm -rf evas*
sudo rm -rf libecore*
sudo rm -rf libector*
sudo rm -rf libedje*
sudo rm -rf libeet*
sudo rm -rf libeeze*
sudo rm -rf libefl*
sudo rm -rf libefreet*
sudo rm -rf libeina*
sudo rm -rf libeio*
sudo rm -rf libeldbus*
sudo rm -rf libelementary*
sudo rm -rf libelocation*
sudo rm -rf libelua*
sudo rm -rf libembryo*
sudo rm -rf libemile*
sudo rm -rf libemotion*
sudo rm -rf libeo*
sudo rm -rf libeolian*
sudo rm -rf libephysics*
sudo rm -rf libethumb*
sudo rm -rf libevas*

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
sudo rm -rf ethumb*
sudo rm -rf evas*
sudo rm -rf terminology*

cd /usr/local/share/applications/
sudo sed -i '/enlightenment_filemanager/d' mimeinfo.cache

cd /usr/local/share/icons/
sudo rm -rf emixer*
sudo rm -rf Enlightenment*

cd /usr/local/share/gdb/
sudo rm -rf auto-load/usr/local/lib/libeo*

cd /usr/share/
sudo rm -rf xsessions/enlightenment.desktop
cd /usr/share/dbus-1/services/
sudo rm -rf org.enlightenment.Ethumb.service

cd $HOME

find /usr/local/share/locale/*/LC_MESSAGES/ 2>/dev/null | while read -r I
do
    if [ -f "$I/efl.mo" ]; then
        cd "$I" && sudo rm -rf efl*
    fi
done

find /usr/local/share/locale/*/LC_MESSAGES/ 2>/dev/null | while read -r I
do
    if [ -f "$I/enlightenment.mo" ]; then
        cd "$I" && sudo rm -rf enlightenment*
    fi
done

find /usr/local/share/locale/*/LC_MESSAGES/ 2>/dev/null | while read -r I
do
    if [ -f "$I/terminology.mo" ]; then
        cd "$I" && sudo rm -rf terminology*
    fi
done
}

install_go () {
clear; printf "\n$BLD%s $OFF%s\n\n" "Proceeding to install Enlightenment 22..."

if [ ! -d $E22 ]; then
leftover_detect
fi

beep_attention
zen_warn 2>/dev/null; sleep 1

if grep -q ppa /var/lib/apt/lists/*ppa* &>/dev/null; then
    bin_deps
    ls_ppa
else
    unset -f ls_ppa
    bin_deps
fi

cd $HOME; mkdir -p $E22; cd $E22

$TITLE "Downloading Source Code . . ."
printf "\n\n$BLD%s $OFF%s\n\n" "Fetching git code..."
$CLONEFL; echo
$CLONE22; echo
$CLONETY; echo

ls_dir

$TITLE "Processing Enlightenment Programs . . ."
echo; beep_question

read -t 10 -p "Build internationalization (i18n) support \
in Enlightenment? [y/N] " answer
case $answer in
  [yY] )
    build_std; echo
    ;;
  [nN] )
    build_no_nls; echo
    ;;
  *    )
    echo; build_no_nls; echo
    ;;
esac

$TITLE "Finalizing Installation . . ."
printf "\n%s\n\n" "Almost done..."

cd $E22

mkdir -p $HOME/.elementary/themes/

sudo ln -sf \
/usr/local/share/dbus-1/services/org.enlightenment.Ethumb.service \
/usr/share/dbus-1/services/org.enlightenment.Ethumb.service

sudo ln -sf /usr/local/share/xsessions/enlightenment.desktop \
/usr/share/xsessions/enlightenment.desktop

sudo updatedb; beep_ok

$TITLE "Installation Complete."
printf "\n\n$BDY%s %s" "Enlightenment first time wizard tips:"
printf "\n$BDY%s %s" "
Update checking——You can disable this feature because it serves no \
useful purpose."
printf "\n$BDY%s $OFF%s\n\n\n" "
Network management support——Do not install Connman!"
echo; cowsay "No Reboot Required... That's All Folks!"; echo
#~ (Then log out and select Enlightenment on the login screen)
}

update_go () {
clear; printf "\n$BLD%s $OFF%s\n\n" "Proceeding to update Enlightenment 22..."
sleep 1

printf "\n$BLD%s $OFF%s\n\n" "
Satisfying dependencies under Ubuntu ${RELEASE^}..."
if [ $CODE == en ]; then
    sudo apt-get install --yes $DEPS_EN
    sleep 1
else
    sudo apt-get install --yes $DEPS
    sleep 1
fi
echo

$TITLE "Processing Enlightenment Programs . . ."

if [ -f /usr/local/share/locale/$CODE/LC_MESSAGES/enlightenment.mo ]; then
    rebuild_std; echo
else
    echo; beep_question   
    read -t 10 -p "Build internationalization (i18n) support \
in Enlightenment? [y/N] " answer
    case $answer in
      [yY] )
        rebuild_std; echo
        ;;
      [nN] )
        rebuild_no_nls; echo
        ;;
      *    )
        echo; rebuild_no_nls; echo
        ;;
    esac
fi

dpbx_detect

cd $E22

mkdir -p $HOME/.elementary/themes/

sudo ln -sf \
/usr/local/share/dbus-1/services/org.enlightenment.Ethumb.service \
/usr/share/dbus-1/services/org.enlightenment.Ethumb.service

sudo ln -sf /usr/local/share/xsessions/enlightenment.desktop \
/usr/share/xsessions/enlightenment.desktop

sudo updatedb
beep_ok
$TITLE "Update Complete."
echo; cowsay -f www "That's All Folks!"; echo
}

uninstall_e22 () {
clear; echo; read -t 5 -p "Wait 5s or hit Ctrl-C to abort..."

printf "\n\n$BLD%s $OFF%s\n\n" "Proceeding to uninstall Enlightenment 22..."

if [ ! -d $E22 ]; then
    printf "\n$BDR%s %s\n" " NOTHING TO REMOVE!"
    printf "$BDR%s $OFF%s\n\n" " PLEASE SELECT ANOTHER OPTION."
    exit 1
fi

for I in $EPROGRM
do
    $TITLE "Processing ${I^} . . ."
    cd $E22/$I && remove_prgrm
done

deep_clean

logger -i "onexenius.sh: Enlightenment 22 was successfully uninstalled."

sudo updatedb
beep_ok
echo; cowsay -d "That's All Folks!"; echo
}

uninstall_all () {
clear; echo; read -t 5 -p "Wait 5s or hit Ctrl-C to abort..."

printf "\n\n$BLD%s $OFF%s\n\n" "
Complete uninstallation of E22 and deps, this may take some time."

for I in $EPROGRM
do
    $TITLE "Processing ${I^} . . ."
    cd $E22/$I && remove_prgrm
done

deep_clean

logger -i "onexenius.sh: Enlightenment 22 was successfully uninstalled."

$TITLE "Processing Ubuntu Packages . . ."
echo; printf "\n$BLD%s $OFF%s\n\n" "Removing binary dependencies..."

#~ (Think twice before proceeding with the removal of these packages!
#~  If you're in doubt, take a screenshot for future reference)
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

if [ $RELEASE == zesty ]; then
    sudo apt-get autoremove --yes libopenjp2-7-dev &>/dev/null
fi

printf "\n%s\n\n" "[Output of ubuntu-support-status]"
ubuntu-support-status

echo; beep_question; echo

if [ -d $HOME/.ccache/ ]; then
    read -t 10 -p "Remove hidden ccache folder (compiler cache)? [y/N] " answer
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

echo

if [ "$(pidof dropbox)" ]; then
    printf "%s\n\n" "
You might also want to delete some folders (E backups) in your Dropbox..."
fi

if [ -d $HOME/git-enlightened/ ]; then
    rm -rf $HOME/git-enlightened/
fi

sudo updatedb; beep_ok
printf "\n$BDG%s $OFF%s\n\n" "Uninstall Complete."
}

go_debug () {
clear; printf "\n$BLD%s $OFF%s\n\n" "Proceeding to update Enlightenment 22..."
sleep 1

if [ ! -d $E22 ]; then
    printf "\n$BDR%s %s\n" " NOTHING TO DEBUG!"
    printf "$BDR%s $OFF%s\n\n" " PLEASE SELECT ANOTHER OPTION."
    exit 1
fi

printf "\n$BLD%s $OFF%s\n\n" "
Satisfying dependencies under Ubuntu ${RELEASE^}..."
if [ $CODE == en ]; then
    sudo apt-get install --yes $DEPS_EN
    sleep 1
else
    sudo apt-get install --yes $DEPS
    sleep 1
fi

$TITLE "Processing Enlightenment Programs . . ."
echo

rebuild_for_debug
wmctrl -r :ACTIVE: -b toggle,maximized_vert,maximized_horz
printf "\n$BDY%s %s\n" "Launching Enlightenment into a Xephyr window..."
printf "$BDY%s %s" "You may experience slow performance in debug mode!"
printf "\n$BDY%s %s" "
Log out of Enlightenment and close the Xephyr window when you are done."
printf "\n$BDY%s $OFF%s\n" "
Then enter q to end the debugging session (quit gdb)."
sleep 6

##~ (See ./xdebug.sh --help for options)
cd $HOME/Enlightenment22/enlightenment/ && ./xdebug.sh
printf "\n$BDY%s %s\n" "Please check /var/crash/ for core dumps,"
printf "\n$BDY%s $OFF%s\n\n" "and look for a file called \
.e-crashdump.txt in your home folder."
}

optim_go () {
clear; printf "\n$BLD%s $OFF%s\n\n" "Proceeding to update Enlightenment 22..."
sleep 1

printf "\n$BLD%s $OFF%s\n\n" "
Satisfying dependencies under Ubuntu ${RELEASE^}..."
if [ $CODE == en ]; then
    sudo apt-get install --yes $DEPS_EN
    sleep 1
else
    sudo apt-get install --yes $DEPS
    sleep 1
fi
echo

$TITLE "Processing Enlightenment Programs . . ."

if [ -f /usr/local/share/locale/$CODE/LC_MESSAGES/enlightenment.mo ]; then
    rebuild_optim; echo
else
    echo; beep_question  
    ##~  (BUILD TEST: Answer yes!)
    read -t 10 -p "Build internationalization (i18n) support \
in Enlightenment? [y/N] " answer
    case $answer in
      [yY] )
        rebuild_optim; echo
        ;;
      [nN] )
        rebuild_optim_no_nls; echo
        ;;
      *    )
        echo; rebuild_optim_no_nls; echo
        ;;
    esac
fi

dpbx_detect

cd $E22

mkdir -p $HOME/.elementary/themes/

sudo ln -sf \
/usr/local/share/dbus-1/services/org.enlightenment.Ethumb.service \
/usr/share/dbus-1/services/org.enlightenment.Ethumb.service

sudo ln -sf /usr/local/share/xsessions/enlightenment.desktop \
/usr/share/xsessions/enlightenment.desktop

sudo updatedb; beep_ok
$TITLE "Optimization completed."
sleep 1; echo
cowsay -f flaming-sheep "Full throttle, baby!"; echo
}

do_tests () {
if [ -x /usr/bin/wmctrl ]; then
    wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz
fi

printf "\n\n$BLD%s $OFF%s\n" "SCANNING SYSTEM AND GIT REPOSITORIES..."; sleep 1

if systemd-detect-virt -q --container; then
    printf "\n$BDR%s %s\n" "
 ONEXENIUS.SH IS NOT INTENDED FOR USE INSIDE CONTAINERS."
    printf "$BDR%s $OFF%s\n\n" " SCRIPT ABORTED."
    exit 1
fi

if [ $RELEASE == zesty ] || [ $RELEASE == xenial ]; then
    printf "\n$BDG%s $OFF%s\n\n" "Ubuntu ${RELEASE^}... OK"; sleep 1
else
    printf "\n$BDR%s $OFF%s\n\n" " UNSUPPORTED OPERATING SYSTEM."
    exit 1
fi

if [ $? -ne 0 ]; then
    printf "\n$BDR%s %s\n" " REMOTE HOST IS UNREACHABLE——TRY AGAIN LATER"
    printf "$BDR%s $OFF%s\n\n" " OR VERIFY YOUR NETWORK CONNECTION."
    exit 1
fi

dpkg -l | egrep -w 'e17|e20|enlightenment' &>/dev/null
if [ $? == 0 ]; then
    printf "\n$BDR%s %s\n" " ANOTHER VERSION OF ENLIGHTENMENT IS ALREADY INSTALLED AND"
    printf "\n$BDR%s %s\n" " THESE TWO VERSIONS ARE NOT COMPATIBLE WITH EACH OTHER."
    printf "$BDR%s $OFF%s\n\n" " SCRIPT ABORTED."
    exit 1
fi

if [ "$(pidof enlightenment)" ]; then
    printf "\n$BDR%s $OFF%s\n\n" "
 PLEASE LOG IN TO ${DISTRIBUTOR^^} TO EXECUTE THIS SCRIPT."
    exit 1
fi

ping -c 2 git.enlightenment.org &>/dev/null
if [ $? -ne 0 ]; then
    printf "\n$BDR%s %s\n" " REMOTE HOST IS UNREACHABLE——TRY AGAIN LATER"
    printf "$BDR%s $OFF%s\n\n" " OR VERIFY YOUR NETWORK CONNECTION."
    exit 1
fi
}

main () {
trap '{ printf "\n$BDR%s $OFF%s\n\n" " KEYBOARD INTERRUPT."; exit 130; }' INT

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
    uninstall_all

elif [ $INPUT == 5 ]; then
    go_debug

elif [ $INPUT == 6 ]; then
    optim_go

else
    echo; beep_exit; exit 1
fi
}

main
