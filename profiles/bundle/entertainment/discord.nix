{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    webcord
  ];

  persist.home.directories = [
    ".config/WebCord"
  ];
}
