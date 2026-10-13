#!/bin/bash
#
# Copyright 2022 Enflame. All Rights Reserved.
#

function usage() {
  cat <<EOF
Usage: ./build.sh [command] <version>
Version: go-eflib version
Command:
    all   Build all bins and make tar package.
Example:
    ./build.sh all
EOF
}

if [ -f "../../g_version.txt" ]; then
    source ../../g_version.txt
fi
PKG_VER=${GOEFLIB_1_0_VERSION:-"0.0.0"}


function copy_if_exists() {
     local file_path=$1

     if [ -f "$file_path" ]; then
        echo "File $file_path exists. Copying to efml directory..."
        cp -f "$file_path" efml/
        echo "File copied successfully."
     else
        echo "File $file_path does not exist, use the locally existing efml files."
     fi
}


function clean_all() {
    if [ -d "dist" ]; then
        rm -rf dist
    fi
}
function build_all() {
    echo -e "\033[33mBuilding go-eflib package.\033[0m"

    if [ -d "dist" ]; then
        rm -rf dist
    fi

    PKG_DIR="dist/go-eflib_${PKG_VER}"
    mkdir -p ${PKG_DIR}

    cp -rf go-eflib_1.0/* ${PKG_DIR}

    echo -e "\033[33mgo-eflib build successfully.\033[0m"
}

function main() {
    [[ "$EUID" -ne 0 ]] && { echo "[INFO] Run as non-root"; }
    [[ "$#" -lt 1 ]] && { usage >&2; exit 1; }

    case $1 in
    "clean")
        clean_all
        ;;
    "all")
        build_all
       ;;
    *)
        usage
        exit 1
        ;;
    esac
}

main "$@"
