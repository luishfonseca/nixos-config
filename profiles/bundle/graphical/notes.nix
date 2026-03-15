{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    notesnook
  ];

  persist.home.directories = [
    ".config/Notesnook"
  ];
}