#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
	echo "Please run as root"
	exit
fi

if [ "$1" == "--capture" ]; then
	find '/' -mount -path '/nix' -prune -o -type f |
		sed '/\/nix/d' |
		sort |
		xargs sha256sum >/nix/pst/root-checksums.txt
	echo "Checksums captured to /nix/pst/root-checksums.txt"
	exit
fi

find '/' -mount -path '/nix' -prune -o -type f |
	sed '/\/nix/d' |
	sort |
	xargs sha256sum |
	diff -u /nix/pst/root-checksums.txt - |
	colordiff |
	less -R
