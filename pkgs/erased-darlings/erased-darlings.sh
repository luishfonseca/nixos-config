#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

directory_pattern="/$"
created_file_pattern=">f+++++++++"
modified_file_pattern=">fc.*\. "
modified_link_pattern="cLc.*\. "
deleted_file_pattern="*deleting"

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

zfs destroy zroot/crypt/local/root@erased-darlings 2>/dev/null
zfs snapshot zroot/crypt/local/root@erased-darlings

rsync -rlcnvi --delete --exclude='/prev' /.zfs/snapshot/erased-darlings/ /prev |
    grep -v "sending incremental file list" |
    grep -v "${directory_pattern}" |
    sed "s/${created_file_pattern}/${green}created${reset}  /" |
    sed "s/${modified_file_pattern}/${yellow}modified${reset}  /" |
    sed "s/${modified_link_pattern}/${yellow}modified${reset}  /" |
    sed "s/${deleted_file_pattern}/${red}deleted${reset}/"
