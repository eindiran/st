#!/usr/bin/env bash
#===============================================================================
#
#          FILE: install_icons.sh
#
#         USAGE: ./install_icons.sh -t <THEME_PATH> [-i <ICON_PATH>] [-n] [-u] [-f] [-h]
#
#   DESCRIPTION: Call this script to install the st icons for a particular
#                icon theme, then update the icon cache. If the -u flag is used,
#                instead uninstall the icons from the machine.
#
#       OPTIONS: -t: (required) Specify the theme directory.
#                -i: (optional) Specify the icon directory.
#                -n: (optional) Don't refresh the icon cache.
#                -u: (optional) Uninstall the icons.
#                -f: (optional) Force -- don't ask the user for input.
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
    printf "\t\t./install_icons.sh -t <THEME_PATH> [-i <ICON_PATH>] [-u] [-f] [-n] [-h]\n\n"
    printf "\t[OPTIONS]\n"
    printf "\t\t-t (required) -- Specify the theme directory.\n"
    printf "\t\t                 May use relative or absolute paths.\n"
    printf "\t\t-i (optional) -- Specify the icon directory. Defaults to 'pwd'.\n"
    printf "\t\t                 May use relative or absolute paths.\n"
    printf "\t\t-n (optional) -- Don't refresh the icon cache. Defaults to false.\n"
    printf "\t\t-u (optional) -- Uninstall the icons.\n"
    printf "\t\t-f (optional) -- Force; don't ask the user for input during uninstallation.\n"
    printf "\t\t-h (optional) -- Print this message and exit.\n\n"
    printf "\t[REQUIREMENTS]\n"
    printf "\t\t> update-icon-caches\n"
}

printerr() {
    # Print out an error message and exit
    FORMAT_STR="$1"
    shift 1
    # shellcheck disable=SC2068,SC2059
    printf "${FORMAT_STR}" $@
    exit 1
}

# Flags:
THEME_DIRECTORY=""
ICON_DIRECTORY="$(pwd)"
REFRESH_ICON_CACHES=true
UNINSTALL_ICONS=false  # Reverse the polarity
FORCE=false

while getopts "t:i:nufh" o; do
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
        u)
            UNINSTALL_ICONS=true
            ;;
        f)
            FORCE=true
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

if ! "${UNINSTALL_ICONS}"; then
    # Install the icons:
    printf "Installing 'st' icons from %s into theme directory: %s\n" "${ICON_DIRECTORY}" "${THEME_DIRECTORY}"
    cd "${ICON_DIRECTORY}" || printerr "Could not access icon directory: %s\n" "${ICON_DIRECTORY}"
    THEME_NAME="$(basename -- "${THEME_DIRECTORY}")"
    sudo cp --recursive --no-preserve=ownership ./* "${THEME_DIRECTORY}"
    printf "Icons were added to the icon theme '%s'\n" "${THEME_NAME}"

    if "${REFRESH_ICON_CACHES}"; then
        printf "Updating icon cache for '%s'\n" "${THEME_NAME}"
        sudo touch "${THEME_DIRECTORY}"
        sudo update-icon-caches "${THEME_DIRECTORY}"
    fi
else
    # Uninstall the icons:
    printf "Uninstalling 'st' icons in theme directory: %s\n" "${THEME_DIRECTORY}"
    if [ ! -d "${THEME_DIRECTORY}" ]; then
        printerr "Unable to find any directory matching the one specified. Exiting...\n"
    else
        if "${FORCE}"; then
            # If the user already passed the -f flag, they mean business:
            # Don't bother wasting any more time - proceed immediately to jamming stuff
            # into the shredder.
            sudo find "${THEME_DIRECTORY}" -type f -name "st.png" -exec rm {} +
        else
            printf "This command will delete the following files:\n"
            sudo find "${THEME_DIRECTORY}" -type f -name "st.png" -exec echo {} +
            read -p "Are you sure you want to proceed? [y/n] " -n 1 -r REPLY
            echo
            [[ $REPLY =~ [Yy]$ ]] || printerr "Cannot continue without 'y' response\n"
            sudo find "${THEME_DIRECTORY}" -type f -name "st.png" -exec rm {} +
        fi
        THEME_NAME="$(basename -- "${THEME_DIRECTORY}")"
        printf "Uninstallation of 'st' icons for theme '%s' completed successfully!\n" "${THEME_NAME}"
    fi
fi
