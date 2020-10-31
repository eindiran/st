#!/usr/bin/env bash
#===============================================================================
#
#          FILE: install_openbsd.sh
#
#         USAGE: ./install_openbsd.sh [-h]
#
#   DESCRIPTION: Compile and install `st` on OpenBSD.
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
    printf "install_openbsd.sh:\n"
    printf "\tInstall required components for compiling st on OpenBSD.\n\n"
    printf "[USAGE]\n"
    printf "\t\t./install_openbsd.sh [-h]\n\n"
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

printf "Copying config.openbsd.mk to config.mk\n"
cp -a config.openbsd.mk config.mk

printf "Compiling st...\n"
make clean
make || printerr "Compilation of st failed!\n"
sudo make install || printerr "Installation of st failed!\n"
chmod a+x ./st
printf "Compilation complete!\n"
printf "st is available here: %s\n" "$(readlink -f ./st)"
