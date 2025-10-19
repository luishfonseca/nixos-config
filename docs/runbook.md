# Run Book

This run book provides instructions for common procedures.

## Installing new system

- Prepare installation media with [ventoy-nixos](https://github.com/luishfonseca/ventoy-nixos).
- Boot the instalation media on the target, approve it on tailscale.
- Write the disk and network config in `hosts/<target>.nix`.
- Run `prepare-secrets <target>` on the deployer. It must be able to decrypt deployer secrets.
- Run `deploy-anywhere <target> nixos@nixos` on the deployer.

## Failed to import zroot ZFS pool

- Disable Secure Boot in BIOS settings.
- Press `e` in systemd-boot menu to edit boot parameters.
- Add SYSTEMD_SULOGIN_FORCE=1 (this will allow to login into emergency shell).
- Inspect logs to confirm import failure is benign.
- If benign, run `zpool import -f zroot`.
- Reboot the system and re-enable Secure Boot.
