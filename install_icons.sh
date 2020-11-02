#!/bin/bash -
#===============================================================================
#
#          FILE: install_icons.sh
#
#         USAGE: ./install_icons.sh -t <THEME_PATH> [-i <ICON_PATH>] [-n] [-h]
#
#   DESCRIPTION: Call this script to install the st icons for a particular
#                icon theme, then update the icon cache.
#
#       OPTIONS: -t: (required) Specify the theme directory.
#                -i: (optional) Specify the icon directory.
#                -n: (optional) Don't refresh the icon cache.
#                -h: (optional) Print the usage message and exit.
#
#  REQUIREMENTS: update-icon-caches
#         NOTES: ---
#        AUTHOR: Elliott Indiran <elliott.indiran@protonmail.com>
#       CREATED: 11/01/2020
#===============================================================================

set -Eeuo pipefail

usage() {
    # Print the usage info
    printf "install_icons.sh:\n"
    printf "\tInstall 'st' icons on Linux-based systems.\n\n"
    printf "\t[USAGE]\n"
    printf "\t\t./install_icons.sh -t <THEME_PATH> [-i <ICON_PATH>] [-n] [-h]\n\n"
    printf "\t[OPTIONS]\n"
    printf "\t\t-t (required) -- Specify the theme directory.\n"
    printf "\t\t                 May use relative or absolute paths.\n"
    printf "\t\t-i (optional) -- Specify the icon directory.\n"
    printf "\t\t                 May use relative or absolute paths.\n"
    printf "\t\t                 Defaults to 'pwd'.\n"
    printf "\t\t-n (optional) -- Don't refresh the icon cache.\n"
    printf "\t\t                 Defaults to false.\n"
    printf "\t\t-h (optional) -- Print this message and exit.\n\n"
    printf "\t[REQUIREMENTS]\n"
    printf "\t\t> update-icon-caches\n"
}

# Flags:
THEME_DIRECTORY=""
ICON_DIRECTORY="$(pwd)"
REFRESH_ICON_CACHES=true

while getopts "t:i:nh" o; do
    case "${o}" in
        t)
            THEME_DIRECTORY="${OPTARG}"
            ;;
        i)
            ICON_DIRECTORY="${OPTARG}"
            ;;
        n)
            REFRESH_ICON_CACHES=false
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

if [ -z "${THEME_DIRECTORY}" ]; then
    usage
    exit 1
fi

cd "${ICON_DIRECTORY}" || printerr "Could not access icon directory: %s\n" "${ICON_DIRECTORY}"
THEME_NAME="$(basename -- "${THEME_DIRECTORY}")"
sudo cp --recursive --no-preserve=ownership ./* "${THEME_DIRECTORY}"
printf "Icons were added to the icon theme '%s'\n" "${THEME_NAME}"

if "${REFRESH_ICON_CACHES}"; then
    printf "Updating icon cache for '%s'\n" "${THEME_NAME}"
    sudo touch "${THEME_DIRECTORY}"
    sudo update-icon-caches "${THEME_DIRECTORY}"
fi
