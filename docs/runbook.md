# Run Book

This run book provides instructions for recovering from common issues.

## Failed to import zroot ZFS pool

- Disable Secure Boot in BIOS settings.
- Press `e` in systemd-boot menu to edit boot parameters.
- Add SYSTEMD_SULOGIN_FORCE=1 (this will allow to login into emergency shell).
- Inspect logs to confirm import failure is benign.
- If benign, run `zpool import -f zroot`.
- Reboot the system and re-enable Secure Boot.
