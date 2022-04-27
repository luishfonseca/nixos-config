{ pkgs, ... }:

{
  # Packages to install in every system.
  environment.systemPackages = with pkgs; [
    thunderbird
    neofetch
    chromium
    discord
    spotify
    pass
  ];
}
