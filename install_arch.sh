#!/usr/bin/env bash
#===============================================================================
#
#          FILE: install_arch.sh
#
#         USAGE: ./install_arch.sh [-h] [-i]
#
#   DESCRIPTION: Compile and install `st` on Arch Linux.
#
#       OPTIONS: -h: Print the help info and exit.
#                -i: Install the icons and .desktop file.
#  REQUIREMENTS: make, A C99 compiler
#         NOTES: ---
#        AUTHOR: Elliott Indiran <elliott.indiran@protonmail.com>
#       CREATED: 10/28/2020
#===============================================================================

set -Eeuo pipefail

printerr() {
    # Print out an error message and exit
    FORMAT_STR="$1"
    shift 1
    # shellcheck disable=SC2068,SC2059
    printf "${FORMAT_STR}" $@
    exit 1
}

usage() {
    # Print the usage info
    printf "install_arch.sh:\n"
    printf "\tInstall required components for compiling st on Arch Linux.\n\n"
    printf "[USAGE]\n"
    printf "\t\t./install_arch.sh [-i] [-h]\n\n"
    printf "\t[OPTIONS]\n"
    printf "\t\t-i (optional) -- Install the icon.\n"
    printf "\t\t-h (optional) -- Print the help/usage info and exit.\n\n"
    printf "[REQUIREMENTS]\n"
    printf "\t\t> make\n"
    printf "\t\t> A C99 compiler\n"
}

# Flags:
INSTALL_ICONS=false
INSTALL_DESKTOP=false

while getopts "ih" o; do
    case "${o}" in
        i)
            # REVISIT: These always have the same value currently.
            INSTALL_ICONS=true
            INSTALL_DESKTOP=true
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

printf "Linking config.mk to config.arch-linux.mk\n"
ln -fns config.arch-linux.mk config.mk

if "${INSTALL_ICONS}"; then
    ICON_THEME_INSTALLED=false  # Track whether we have installed at least one icon theme
    if [ -d /usr/share/icons/hicolor ]; then
        ./install_icons.sh -t /usr/share/icons/hicolor -i assets/icons
        ICON_THEME_INSTALLED=true
    fi
    if [ -d /usr/share/icons/elementary-xfce ]; then
        ./install_icons.sh -t /usr/share/icons/elementary-xfce -i assets/icons
        ./install_icons.sh -t /usr/share/icons/elementary-xfce-dark -i assets/icons
        ./install_icons.sh -t /usr/share/icons/elementary-xfce-darker -i assets/icons
        ./install_icons.sh -t /usr/share/icons/elementary-xfce-darkest -i assets/icons
        ICON_THEME_INSTALLED=true
    fi
    if "${ICON_THEME_INSTALLED}"; then
        printf "Icon installation complete\n"
    else
        # If the user has neither of the two themes above at all (which
        # is unlikely given how common `hicolor` is), this script can
        # be changed to support another icon theme.
        printf "[WARNING] No icons were installed!\n"
    fi
fi

printf "Installing dependencies...\n"
# We need to install HarfBuzz, the various X libraries, fontconfig, pkg-config,
# desktop-file-install, and dmenu:
pacman -S desktop-file-utils harfbuzz libx11 libxft libxext fontconfig pkgconf dmenu
printf "Installation of dependencies complete!\n"

printf "Compiling st...\n"
make clean
make || printerr "Compilation of st failed!\n"
sudo make install || printerr "Installation of st failed!\n"
chmod a+x ./st
printf "Compilation complete!\n"
printf "st is available here: %s\n" "$(readlink -f ./st)"

if "${INSTALL_DESKTOP}"; then
    printf "Installing st.desktop file...\n"
    sudo desktop-file-install st.desktop
    printf "st.desktop was successfully installed!\n"
fi

printf "Installation complete!\n"
