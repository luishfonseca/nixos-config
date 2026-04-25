{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    kimi-cli
  ];

  persist.home.directories = [".kimi"];
}
