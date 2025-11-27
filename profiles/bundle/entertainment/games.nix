{
  pkgs,
  config,
  ...
}: {
  programs.steam = {
    enable = true;
    protontricks.enable = true;
  };

  hardware.xpadneo.enable = true;

  hm.home.packages = with pkgs; [lhf.wrye-bash];

  persist.home.directories = [".local/share/Steam"];

  # This won't create the partition if added after installation
  disko.devices.lvm_vg.root_pool.lvs.games = {
    size = "100G";
    content = {
      type = "filesystem";
      format = "ext4";
      extraArgs = ["-O" "casefold"];
      mountOptions = ["noatime"];
      mountpoint = "/home/${config.user.name}/games";
    };
  };
}
