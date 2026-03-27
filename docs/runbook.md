# Run Book

This run book provides instructions for common procedures.

## Installing new system

- Prepare installation media with [ventoy-nixos](https://github.com/luishfonseca/ventoy-nixos).
- Boot the instalation media on the target, approve it on tailscale.
- Write the disk and network config in `hosts/<target>.nix`.
- Run `prepare-secrets <target>` on the deployer. It must be able to decrypt deployer secrets.
- Run `deploy-anywhere <target> nixos@nixos` on the deployer.

### If the machine is very underpowered

Enable zram:
```sh
modprobe zram
zramctl /dev/zram0 --size $(free -m | awk '/Mem:/{print $2}')M --algorithm zstd
mkswap /dev/zram0
swapon -p 100 /dev/zram0

sysctl vm.swappiness=150
echo 3 > /proc/sys/vm/drop_caches
```

You may also need to enable it on the original OS.

Additionally, use the following deploy flags `--no-substitute-on-destination --build-on local`

## Emergency Shell

- Disable Secure Boot in BIOS settings.
- Press `e` in systemd-boot menu to edit boot parameters.
- Add SYSTEMD_SULOGIN_FORCE=1 (this will allow to login into emergency shell).
