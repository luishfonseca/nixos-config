#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

function gather_facts() {
    ls /keyvol/sshvol_recovery.key >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        REMOTE=1
    else
        REMOTE=0
    fi

    SECURE_BOOT=$(sbctl status --json | jq -r '.secure_boot')
    if [ "${SECURE_BOOT}" = "true" ]; then
        SECURE_BOOT=1
    else
        SECURE_BOOT=0
    fi
}

function ask() {
    QUESTION=$1
    DEFAULT=$2

    if [ "${DEFAULT}" = "Y" ]; then
        read -p "${QUESTION} [Y/n]: " ANSWER
        if [ "${ANSWER}" = "N" ] || [ "${ANSWER}" = "n" ]; then
            echo 0
        else
            echo 1
        fi
    else
        read -p "${QUESTION} [y/N]: " ANSWER
        if [ "${ANSWER}" = "Y" ] || [ "${ANSWER}" = "y" ]; then
            echo 1
        else
            echo 0
        fi
    fi
}

exe() { echo "> $@" ; "$@" ; }

gather_facts

if [ $SECURE_BOOT -eq 0 ]; then
    echo "Secure boot is not enabled. Exiting..."
    exit 1
fi

CONTINUE=1
if [ $REMOTE -eq 1 ]; then
    WITH_PASSWORD=$(ask "Do you want to be asked for a password?" "Y")
    if [ $WITH_PASSWORD -eq 0 ]; then
        echo "WARNING: Both unattended unlock and remote unlock are enabled. Consider disabling remote unlock."
        CONTINUE=$(ask "Do you want to continue?" "N")
    fi
else
    WITH_PASSWORD=$(ask "Do you want to be asked for a password?" "N")
    if [ $WITH_PASSWORD -eq 1 ]; then
        echo "WARNING: Both unattended unlock and remote unlock are disabled. You won't be able to unlock the disks remotely."
        CONTINUE=$(ask "Do you want to continue?" "N")
    fi
fi

if [ $CONTINUE -eq 0 ]; then
    echo "Exiting..."
    exit 1
fi

exe systemd-cryptenroll /dev/zvol/zroot/keyvol --wipe-slot=tpm2
if [ $WITH_PASSWORD -eq 1 ]; then
    exe systemd-cryptenroll /dev/zvol/zroot/keyvol --unlock-key-file=/keyvol/keyvol_recovery.key --tpm2-device=auto --tpm2-with-pin=yes --tpm2-pcrs=7
else
    exe systemd-cryptenroll /dev/zvol/zroot/keyvol --unlock-key-file=/keyvol/keyvol_recovery.key --tpm2-device=auto --tpm2-with-pin=no --tpm2-pcrs=7
fi

if [ $REMOTE -eq 1 ]; then
    exe systemd-cryptenroll /dev/zvol/zroot/sshvol --wipe-slot=tpm2
    exe systemd-cryptenroll /dev/zvol/zroot/sshvol --unlock-key-file=/keyvol/sshvol_recovery.key --tpm2-device=auto --tpm2-pcrs=7
fi
