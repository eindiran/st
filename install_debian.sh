#!/usr/bin/env bash
#===============================================================================
#
#          FILE: install_debian.sh
#
#         USAGE: ./install_debian.sh [-d HARFBUZZ_DIRECTORY] [-s] [-m] [-n] [-h]
#
#   DESCRIPTION: Compile and install `st` on Ubuntu/Debian-flavoured distros.
#
#       OPTIONS: -d: (optional) Use this flag to set the directory where HarfBuzz
#                    will be downloaded to (and built in). Takes a relative or
#                    absolute path as an argument.
#                -s: (optional) Skip checking whether HarfBuzz is installed
#                    (default: false).
#                -m: (optional) Use meson to build HarfBuzz
#                    (default: autoconf/automake).
#                -n: (optional) Don't build HarfBuzz (default: false).
#                -h: Print this help/info message and exit.
#
#  REQUIREMENTS: apt-get, git, make, a C99 compiler
#         NOTES: ---
#        AUTHOR: Elliott Indiran <elliott.indiran@protonmail.com>
#       CREATED: 10/28/2020
#===============================================================================
set -Eeuo pipefail

usage() {
    # Print the usage info
    printf "install_debian.sh:\n"
    printf "\tInstall required components for compiling st on Debian-based distros.\n\n"
    printf "\t[USAGE]\n"
    printf "\t\t./install_debian.sh [-d <HARFBUZZ_DIR>] [-s] [-m] [-n] [-h]\n\n"
    printf "\t[OPTIONS]\n"
    printf "\t\t-d (optional) -- Set directory where HarfBuzz will be downloaded (default: pwd).\n"
    printf "\t\t-s (optional) -- Skip checking whether HarfBuzz is installed (default: false).\n"
    printf "\t\t-m (optional) -- Use meson to build HarfBuzz (default: autoconf/automake).\n"
    printf "\t\t-n (optional) -- Don't build HarfBuzz (default: false).\n"
    printf "\t\t-h (optional) -- Print this message and exit.\n\n"
    printf "\t[REQUIREMENTS]\n"
    printf "\t\t> apt-get\n"
    printf "\t\t> git\n"
    printf "\t\t> make\n"
    printf "\t\t> A C99 compiler\n"
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
HARFBUZZ_DIR="$(pwd)"
BUILD_HARFBUZZ=true
USE_MESON=false
SKIP_INCLUDES_CHECK=false

while getopts "d:smnh" o; do
    case "${o}" in
        d)
            HARFBUZZ_DIR="${OPTARG}"
            ;;
        m)
            USE_MESON=true
            ;;
        n)
            BUILD_HARFBUZZ=false
            ;;
        s)
            SKIP_INCLUDES_CHECK=true
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

printf "Linking config.mk to config.debian-linux.mk\n"
ln -fns config.debian-linux.mk config.mk

# Install explicit st dependencies:
printf "Installing st dependencies\n"
sudo apt-get install -y libx11-dev libxft-dev libxext-dev pkg-config libfontconfig1 libfreetype6-dev xclip

if "${BUILD_HARFBUZZ}"; then
    (
        # Install HarfBuzz dependencies:
        printf "Installing HarfBuzz dependencies\n"
        if ${USE_MESON}; then
            printf "Using meson toolchain to build HarfBuzz\n"
            sudo apt-get install -y meson ragel
        else
            printf "Using autoconf/automake toolchain to build HarfBuzz\n"
            sudo apt-get install -y autoconf automake
        fi
        sudo apt-get install -y libtool gtk-doc-tools gcc g++ libglib2.0-dev libcairo2-dev
        # Build HarfBuzz in a subshell to avoid needing pushd/popd/cd
        if [ -n "${HARFBUZZ_DIR}" ]; then
            printf "Using directory %s to build harfbuzz\n" "${HARFBUZZ_DIR}"
            # shellcheck disable=SC2015
            mkdir -p "${HARFBUZZ_DIR}" && cd "${HARFBUZZ_DIR}" || printerr "Failed to create directory: %s\n" "${HARFBUZZ_DIR}"
        fi

        printf "Cloning HarfBuzz repository into %s\n" "$(pwd)/harfbuzz"
        git clone https://github.com/harfbuzz/harfbuzz.git 2> /dev/null || true
        cd harfbuzz
        if ${USE_MESON}; then
            meson build || printerr "Meson build failed. Check meson.logs in %s\n" "$(pwd)"
            meson test -C build || printerr "Meson build failed. Check meson.logs in %s\n" "$(pwd)"
        else
            ./autogen.sh || printerr "autogen.sh script failed!\n"
            # shellcheck disable=SC2015
            make && sudo make install || printerr "Make failed to complete installing HarfBuzz!\n"
        fi

    )
else
    printf "Skipping HarfBuzz build.\n"
fi

if "${SKIP_INCLUDES_CHECK}"; then
    printf "Skipping HarfBuzz includes check...\n"
else
    printf "Checking for HarfBuzz includes...\n"
    if [ -a /usr/local/include/harfbuzz/hb.h ]; then
        printf "Found required files in /usr/local/include/harfbuzz/\n"
    elif [ -a /usr/include/harfbuzz/hb.h ]; then
        printf "Found required files in /usr/include/harfbuzz/\n"
    else
        printf "HarfBuzz files were not found in expected directories\n"
        printf "If you have installed them somewhere else, and the linker will be able to find them, "
        printf "you can skip this check by running this script again with the -s flag.\n"
        printerr "Exiting...\n"
    fi
fi

printf "All st dependencies are installed!\n"
printf "Compiling st...\n"
make clean
make || printerr "Compilation of st failed!\n"
sudo make install || printerr "Installation of st failed!\n"
chmod a+x ./st
printf "Compilation complete!\n"
printf "st is available here: %s\n" "$(readlink -f ./st)"
