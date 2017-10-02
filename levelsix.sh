#!/bin/bash

#~ WARNING: ALPHA QUALITY!

###~ LEVELSIX.SH
#~ This script allows you to easily download, install, update the GIT master
#~ version of Enlightenment 0.22 (aka E22) on Fedora 26 Workstation;
#~ or helps you perform a clean uninstall of E22 GIT.

#~ To execute the script:
#~ 1. Open Terminal (uncheck "Limit scrollback to" in Profile Preferences)
#~ 2. Change to the download folder
#~ 3. Make the script executable with chmod +x
#~ 4. Run it with ./levelsix.sh

#~ Tip for advanced users:
#~ Switching to console mode (tty) will speed up the rebuild process.

#~ (Script debugging)
#~export PS4='+ $LINENO: '
#~export LC_ALL=C
#~set -vx

#~ LEVELSIX is written by batden@sfr.fr,
#~ feel free to use this script as you see fit.

trap '{ printf "\n$bdr%s $off%s\n\n" " KEYBOARD INTERRUPT."; exit 130; }' INT

###~ VARIABLES
BLD="\e[1m"     #~ (Bold text)
BRN="\e[0;31m"  #~ (Brown text)
BDR="\e[1;31m"  #~ (Bold red text)
BDG="\e[1;32m"  #~ (Bold green text)
BDY="\e[1;33m"  #~ (Bold yellow text)
OFF="\e[0m"     #~ (Turn off ansi colors)

export CPPFLAGS=-I/usr/local/include
export LDFLAGS=-L/usr/local/lib
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
export CC="ccache gcc"
export CXX="ccache g++"
export USE_CCACHE=1
export CCACHE_COMPRESS=1

NCPU="$(getconf _NPROCESSORS_ONLN)"
NJOBS="$((NCPU*2))"
export MAKE="make -j $NJOBS"

PREFIX=/usr/local
E22="$HOME/Enlightenment22"
GEN="./autogen.sh --prefix=$PREFIX"
SMIL="sudo make install"
RELEASE=$(rpm -E %fedora)

CURVERNUM=0.8

DEPS="automake bluez-libs-devel bullet-devel ccache check-devel cowsay \
curl-devel dbus-devel doxygen fontconfig-devel freetype-devel fribidi-devel \
gcc gcc-c++ gettext-devel giflib-devel glib2-devel gstreamer1-devel \
gstreamer1-plugins-base-devel harfbuzz-devel ibus-devel ImageMagick \
kernel-devel libdrm-devel libinput-devel libjpeg-turbo-devel libpng-devel \
mesa-libGL-devel mesa-libGLES-devel libmount-devel libproxy-devel LibRaw-devel \
librsvg2-devel libsndfile-devel libspectre-devel libtiff-devel libtool \
libunwind-devel libwebp-devel libX11-devel libxkbcommon-devel libxkbfile-devel \
libXcursor-devel libXdamage-devel libXext-devel libXinerama-devel \
libXScrnSaver-devel libXtst-devel luajit-devel make mesa-libgbm-devel \
mesa-libwayland-egl-devel openjpeg-devel openssl-devel pam-devel perf \
poppler-cpp-devel pulseaudio-libs-devel scim-devel systemd-devel texlive-base \
uuid-devel valgrind-devel wayland-devel wayland-protocols-devel \
xcb-util-keysyms-devel xine-lib-devel xorg-x11-server-Xephyr"

#~ Rawhide support required?
#~ sudo dnf install fedora-repos-rawhide
#~ sudo dnf --enablerepo=rawhide --nogpgcheck upgrade wayland-devel wayland-protocols-devel

CLONEFL="git clone https://git.enlightenment.org/core/efl.git"
CLONE22="git clone https://git.enlightenment.org/core/enlightenment.git"
CLONETY="git clone https://git.enlightenment.org/apps/terminology.git"
EPROGRM="efl enlightenment terminology"

if [ $RELEASE == 26 ]; then
    printf "\n$BDG%s $OFF%s\n\n" "Fedora $RELEASE... OK"; sleep 1
else
    printf "\n$BDR%s $OFF%s\n\n" " UNSUPPORTED OPERATING SYSTEM."
    exit 1
fi

#if [ "$(pidof enlightenment)" ]; then
    #printf "\n$BDR%s $OFF%s\n\n" "
 #PLEASE LOG IN TO YOUR DEFAULT DESKTOP ENVIRONMENT BEFORE RUNNING THIS SCRIPT."
    #exit 1
#fi

printf "\n%s\n" "Script version is $CURVERNUM, you use this script at your \
own risk"
printf "%s\n\n" "and cannot expect any support."
sleep 1

###~ FUNCTIONS
bin_deps ()  {
sudo dnf update
sudo dnf install $DEPS
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

build () {
export CFLAGS="-O3 -ffast-math -march=native"
export CXXFLAGS="-O3 -ffast-math -march=native"

for I in $EPROGRM; do
    cd $E22/$I
    printf "\n$BLD%s $OFF%s\n\n" "Building $I..."
        case $I in
            efl) $GEN --enable-cxx-bindings --enable-harfbuzz \
            --enable-image-loader-webp --enable-multisense --enable-systemd \
            --enable-valgrind --enable-xine --enable-xinput22 
            ;;
            enlightenment) $GEN --enable-mount-eeze --disable-wl-desktop-shell \
            --with-profile=FAST_PC
            ;;
            *) $GEN
            ;;
        esac
    make
    $SMIL
    sudo ldconfig
done
}

rebuild () {
export CFLAGS="-O3 -ffast-math -march=native"
export CXXFLAGS="-O3 -ffast-math -march=native"

for I in $EPROGRM; do
    cd $E22/$I
    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    make distclean &>/dev/null
    git reset --hard &>/dev/null
    git pull
    echo
        case $I in
            efl) $GEN --enable-cxx-bindings --enable-harfbuzz \
            --enable-image-loader-webp --enable-multisense --enable-systemd \
            --enable-valgrind --enable-xine --enable-xinput22 
            ;;
            enlightenment) $GEN --enable-mount-eeze --disable-wl-desktop-shell \
            --with-profile=FAST_PC
            ;;
            *) $GEN
            ;;
        esac
    make
    $SMIL
    sudo ldconfig
done
}

rebuild_wayland () {
export CFLAGS="-O3 -ffast-math -march=native"
export CXXFLAGS="-O3 -ffast-math -march=native"

for I in $EPROGRM; do
    cd $E22/$I
    printf "\n$BDY%s $OFF%s\n\n" "Updating $I..."
    make distclean &>/dev/null
    git reset --hard &>/dev/null
    git pull
    echo
        case $I in
            efl) $GEN --enable-cxx-bindings --enable-drm --enable-egl \
            --enable-elput --enable-gl-drm  --enable-harfbuzz \
            --enable-image-loader-webp --enable-multisense --enable-systemd \
            --enable-valgrind --enable-wayland --enable-xine --enable-xinput22 \
            --with-opengl=es
            ;;
            enlightenment) $GEN --enable-mount-eeze --enable-wayland \
            --enable-wayland-egl --enable-xwayland --with-profile=FAST_PC
            ;;
            *) $GEN
            ;;
        esac
    make
    $SMIL
    sudo ldconfig
done
}

remove () {
case $I in
    efl) printf "\n$BLD%s $OFF%s\n\n" "Cleaning $I... please wait."
    ;;
    *)   printf "\n$bld%s $OFF%s\n\n" "Cleaning $I..."
    ;;
esac
sudo make uninstall &>/dev/null
make distclean &>/dev/null
echo
}

deep_clean () {
echo; printf "\n$BLD%s $OFF%s\n\n" "Deeper cleaning..."; sleep 1

cd $E22
sudo rm -rf enlightenment/
sudo rm -rf terminology/
sudo rm -rf efl/

cd $HOME
rm -rf Enlightenment22/
rm -rf .e/
rm -rf .elementary/
rm -rf .cache/efreet/
rm -rf .cache/evas_gl_common_caches/
rm -rf .config/terminology/

cd /etc/
sudo rm -rf enlightenment/

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
sudo rm -rf elput*
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
sudo rm -rf libelput*
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

cd /usr/local/lib/pkgconfig/
sudo rm -rf ecore*
sudo rm -rf elput*
sudo rm -rf evas*

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

find /usr/local/share/locale/*/LC_MESSAGES/ 2>/dev/null| while read -r I; do
    if [ -f "$I/terminology.mo" ]; then
        cd "$I" && sudo rm -rf terminology*
    fi
done
}

###~ SELECTION
INPUT=0
printf "\n$BLD%s $OFF%s\n" "Please enter the number of your choice:"

if [ $INPUT -lt 1 ]; then
    printf "\n$BDG%s $OFF%s\n\n" "1. Install Enlightenment 22."
    printf "$BDG%s %s\n\n" "2. Update and rebuild my E22 installation."
    printf "$BDY%s $OFF%s\n\n" "3. Update and rebuild E22 with Wayland support \
(unstable)."
    printf "$BRN%s $OFF%s\n\n" "4. Uninstall all E22 programs then clean up."
    sleep 1
    printf "$BLD%s $OFF%s\n\n" "—  Or press Ctrl-C to quit."
    read INPUT
fi

if [ $INPUT == 1 ]; then
    clear; printf "\n$BLD%s $OFF%s\n\n" "
Proceeding to install Enlightenment 22..."
    sleep 1
    bin_deps

    cd $HOME; mkdir -p $E22; cd $E22

    printf "\n\n$BLD%s $OFF%s\n\n" "Fetching git code..."
    $CLONEFL; echo
    $CLONE22; echo
    $CLONETY; echo

    ls_dir
    build
    printf "\n%s\n\n" "Almost done..."

    cd $E22

    mkdir -p $HOME/.elementary/themes/

    sudo ln -sf \
    /usr/local/share/dbus-1/services/org.enlightenment.Ethumb.service \
    /usr/share/dbus-1/services/org.enlightenment.Ethumb.service

    sudo ln -sf /usr/local/share/xsessions/enlightenment.desktop \
    /usr/share/xsessions/enlightenment.desktop

    sudo updatedb

    printf "\n\n$BDY%s %s" "Enlightenment first time wizard tips:"
    printf "\n$BDY%s %s" "
Update checking——You can disable this feature because it serves no \
useful purpose."
    printf "\n$BDY%s $OFF%s\n\n\n" "
Network management support——Do not install Connman!"
    echo; cowsay "No Reboot Required... That's All Folks!"; echo
    #~ (Then log out and select Enlightenment on the login screen)

elif [ $INPUT == 2 ]; then
    clear; printf "\n$BLD%s $OFF%s\n\n" "
Proceeding to update Enlightenment 22..."
    sleep 1
    bin_deps
    rebuild

    sudo updatedb
    echo; cowsay -f www "That's All Folks!"; echo

elif [ $INPUT == 3 ]; then
    clear; printf "\n\n$BDY%s %s\n" "
Warning: Running Enlightenment as a Wayland compositor is not considered safe"
    printf "$BDY%s" "for everyday desktop use, though it is functional enough \
to test or"
    printf "\n$BDY%s $OFF%s\n\n" "use in specialized environments."
    sleep 6
    read -t 5 -p "Wait 5s or hit Ctrl-C to abort..."; echo

    printf "\n\n$BDY%s $OFF%s\n\n" "Proceeding to update Enlightenment 22..."
    sleep 1
    bin_deps
    rebuild_wayland

    sudo updatedb
    echo; cowsay -f www "Now log out of your existing session and press  \
Ctrl-Alt-F2 to switch to tty2, then enter your credentials and type:  \
enlightenment_start"; echo

#~ Tip from fedorafaq.org:
#~ "To switch your entire screen to a terminal, press Ctrl-Alt-F2.
#~ You can then switch between six different terminals by using Alt-F2 through
#~ Alt-F6. Pressing Alt-F1 will bring you back to your graphical environment."

elif [ $INPUT == 4 ]; then
    clear; echo; read -t 5 -p "Wait 5s or hit Ctrl-C to abort..."

    printf "\n\n$BLD%s $OFF%s\n\n" "
Complete uninstallation of E22, this may take some time."

    for I in $EPROGRM; do
        cd $E22/$I && remove
    done

    deep_clean
    
    sudo updatedb
    printf "\n$BDG%s $OFF%s\n\n" "Uninstall Complete."

else
    echo; exit 1
fi
