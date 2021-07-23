# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, options, inputs, ... }:

{

  imports = [
      ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # /tmp shouldn't persist over reboots
  boot.tmpOnTmpfs = true;

  networking.hostName = "sirius"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "Europe/Lisbon";

  networking.useDHCP = false;
  networking.interfaces.enp35s0.useDHCP = true;

  # Keyboard Layout
  console.useXkbConfig = true;
  services.xserver = {
    layout = "us";
    xkbVariant = "colemak_dh";
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    
    displayManager.lightdm.enable = true;

    displayManager.lightdm.greeters.mini = {
      enable = true;
      user = "luis";
    };
  };

  services.interception-tools = {
    enable = true;
    plugins = [ pkgs.interception-tools-plugins.caps2esc ];
  };

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Define a user account.
  nix.trustedUsers = [ "root" "@wheel" ];
  users.users.luis = {
    shell = pkgs.fish;
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      (nerdfonts.override { fonts = [ "IBMPlexMono" ]; })
      ibm-plex
      noto-fonts-cjk
      noto-fonts-emoji
    ];

    fontconfig.defaultFonts = {
      serif = [ "IBM Plex Serif" "Noto Sans CJK JP" ];
      sansSerif = [ "IBM Plex Sans" "Noto Sans CJK JP" ];
      monospace = [ "BlexMono Nerd Font Mono" "Noto Sans Mono CJK JP" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}

