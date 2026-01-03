{pkgs, ...}: {
  programs.thunderbird.enable = true;
  persist.home.directories = [".thunderbird"];
}
