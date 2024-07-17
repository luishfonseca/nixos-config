#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

find '/' -mount -path '/nix' -prune -o -type f |
    sed '/\/nix/d' |
    sort |
    xargs sha256sum |
    diff -u /pst/local/root-checksums.txt - |
    colordiff |
    less -R
