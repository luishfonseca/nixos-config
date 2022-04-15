{ pkgs, ... }:

{
  # Packages to install in every system.
  environment.systemPackages = with pkgs; [
    neofetch
    htop
  ];
}
