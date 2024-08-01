#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
	echo "Please run as root"
	exit
fi

function gather_facts() {
	SECURE_BOOT=$(sbctl status --json | jq -r '.secure_boot')
	if [ "${SECURE_BOOT}" = "true" ]; then
		SECURE_BOOT=1
	else
		SECURE_BOOT=0
	fi

	KEY_FILE="/pst/data/fsroot_recovery.key"
	if ! ls $KEY_FILE >/dev/null 2>&1; then
		KEY_FILE="/fsroot_recovery.key"
	fi

	if ! ls $KEY_FILE >/dev/null 2>&1; then
		echo "Unlock key file not found. Exiting..."
		exit 1
	fi
}

function ask() {
	QUESTION=$1
	DEFAULT=$2

	if [ "${DEFAULT}" = "Y" ]; then
		read -r -p "${QUESTION} [Y/n]: " ANSWER
		if [ "${ANSWER}" = "N" ] || [ "${ANSWER}" = "n" ]; then
			echo 0
		else
			echo 1
		fi
	else
		read -r -p "${QUESTION} [y/N]: " ANSWER
		if [ "${ANSWER}" = "Y" ] || [ "${ANSWER}" = "y" ]; then
			echo 1
		else
			echo 0
		fi
	fi
}

exe() {
	echo "> $*"
	"$@"
}

gather_facts

if [ $SECURE_BOOT -eq 0 ]; then
	echo "Secure boot is not enabled. Exiting..."
	exit 1
fi

WITH_PASSWORD=$(ask "Do you want to be asked for a password?" "N")

exe systemd-cryptenroll /dev/disk/by-partlabel/disk-os-root --wipe-slot=tpm2
if [ "$WITH_PASSWORD" -eq 1 ]; then
	exe systemd-cryptenroll /dev/disk/by-partlabel/disk-os-root --unlock-key-file=$KEY_FILE --tpm2-device=auto --tpm2-with-pin=yes --tpm2-pcrs=7
else
	exe systemd-cryptenroll /dev/disk/by-partlabel/disk-os-root --unlock-key-file=$KEY_FILE --tpm2-device=auto --tpm2-with-pin=no --tpm2-pcrs=7
fi
