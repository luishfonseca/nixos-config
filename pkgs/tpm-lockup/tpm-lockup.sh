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

	KEY_VOL_KEY="/local/keys/key_vol.key"
	if ! ls "$KEY_VOL_KEY" >/dev/null 2>&1; then
		echo "Key file not found at $KEY_VOL_KEY. Exiting..."
		exit 1
	fi

	RD_SHARED_VOL_KEY="/local/keys/rd_shared_vol.key"
	if ls "$RD_SHARED_VOL_KEY" >/dev/null 2>&1; then
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
	echo "Locking key_vol with TPM2 + password."
elif [ "$WITH_SSH" -eq 0 ] then
	echo "Locking key_vol with TPM2 only. It will be automatically unlocked on boot."
else
	echo "This system was configured with remote unlock. This requires rd_shared to be auto-unlocked. Multiple auto-unlocked disks are not supported."
	exit 1
fi

exe systemd-cryptenroll /dev/zvol/zroot/key_vol --wipe-slot=tpm2
if [ "$WITH_PASSWORD" -eq 1 ]; then
	exe systemd-cryptenroll /dev/zvol/zroot/key_vol --unlock-key-file=$KEY_VOL_KEY --tpm2-device=auto --tpm2-with-pin=yes --tpm2-pcrs=7
else
	exe systemd-cryptenroll /dev/zvol/zroot/key_vol --unlock-key-file=$KEY_VOL_KEY --tpm2-device=auto --tpm2-with-pin=no --tpm2-pcrs=7+15:sha256=0000000000000000000000000000000000000000000000000000000000000000
fi

if [ "$WITH_SSH" -eq 1 ]; then
	echo "Locking rd_shared with TPM2 only. It will be automatically unlocked on boot."

	exe systemd-cryptenroll /dev/zvol/zroot/rd_shared_vol --wipe-slot=tpm2
	exe systemd-cryptenroll /dev/zvol/zroot/rd_shared_vol --unlock-key-file=$RD_SHARED_VOL_KEY --tpm2-device=auto --tpm2-with-pin=no --tpm2-pcrs=7+15:sha256=0000000000000000000000000000000000000000000000000000000000000000
fi
