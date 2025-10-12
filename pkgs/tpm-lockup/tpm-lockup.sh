#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
	echo "Please run as root"
	exit
fi

function gather_facts() {
	SECURE_BOOT=$(sbctl status --json | jq -r '.secure_boot')
	if [ ! "${SECURE_BOOT}" = "true" ]; then
		echo "Secure boot is not enabled. Exiting..."
		exit 1
	fi

	KEYVOL_RECOVERY="/keys/keyvol_recovery.key"
	if ! ls $KEYVOL_RECOVERY >/dev/null 2>&1; then
		echo "Key file not found at $KEYVOL_RECOVERY. Exiting..."
		exit 1
	fi

	SSHVOL_RECOVERY="/keys/sshvol_recovery.key"
	if ls $SSHVOL_RECOVERY >/dev/null 2>&1; then
		WITH_SSH=1
	else
		WITH_SSH=0
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

WITH_PASSWORD=$(ask "Do you want to be asked for a password?" "N")

if [ "$WITH_PASSWORD" -eq 1 ]; then
	echo "Locking keyvol with TPM2 and password."
else
	echo "Locking keyvol with TPM2 only."
fi

exe systemd-cryptenroll /dev/zvol/zroot/keyvol --wipe-slot=tpm2
if [ "$WITH_PASSWORD" -eq 1 ]; then
	exe systemd-cryptenroll /dev/zvol/zroot/keyvol --unlock-key-file=$KEYVOL_RECOVERY --tpm2-device=auto --tpm2-with-pin=yes --tpm2-pcrs=7
else
	exe systemd-cryptenroll /dev/zvol/zroot/keyvol --unlock-key-file=$KEYVOL_RECOVERY --tpm2-device=auto --tpm2-with-pin=no --tpm2-pcrs=7
fi

if [ "$WITH_SSH" -eq 1 ]; then
	echo "Locking sshvol with TPM2 only."

	exe systemd-cryptenroll /dev/zvol/zroot/sshvol --wipe-slot=tpm2
	exe systemd-cryptenroll /dev/zvol/zroot/sshvol --unlock-key-file=$SSHVOL_RECOVERY --tpm2-device=auto --tpm2-with-pin=no --tpm2-pcrs=7
fi
