#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

find '/' -mount -path '/nix' -prune -o -type f |
    sort |
    xargs crc32 |
    diff -u /pst/local/root-crc.txt - |
    colordiff |
    less -R
