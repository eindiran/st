#!/bin/bash -
#===============================================================================
#
#          FILE: install_arch.sh
#
#         USAGE: ./install_arch.sh [-h]
#
#   DESCRIPTION: Compile and install `st` on Arch Linux.
#
#       OPTIONS: -h: Print the help info and exit.
#  REQUIREMENTS: None.
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
    printf "\t\t./install_arch.sh [-h]\n\n"
    printf "\t[OPTIONS]\n"
    printf "\t\t-h (optional) -- Print the help/usage info and exit.\n\n"
    printf "[REQUIREMENTS]\n"
    printf "\t\t> make\n"
    printf "\t\t> A C99 compiler\n"
}

while getopts "h" o; do
    case "${o}" in
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

printf "Copying config.arch-linux.mk to config.mk\n"
cp -a config.arch-linux.mk config.mk

printf "Compiling st...\n"
make clean
make || printerr "Compilation of st failed!\n"
sudo make install || printerr "Installation of st failed!\n"
chmod a+x ./st
printf "Compilation complete!\n"
printf "st is available here: %s\n" "$(readlink -f ./st)"
