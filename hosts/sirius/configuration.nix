# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{

  imports = [
      ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "sirius"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "Europe/Lisbon";

  networking.useDHCP = false;
  networking.interfaces.enp35s0.useDHCP = true;

  console.useXkbConfig = true;

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    layout = "us";
    xkbVariant = "colemak_dh";

    videoDrivers = [ "amdgpu" ];
    
    displayManager = {
      lightdm = {
        enable = true;
        greeter.enable = false;
      };

      autoLogin = {
        enable = true;
        user = "luis";
      };

      defaultSession = "xsession";
      session = [{
        manage = "desktop";
	name = "xsession";
	start = "exec $HOME/.xsession";
      }];
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
  users.defaultUserShell = pkgs.fish;
  users.users.luis = {
    initialPassword = "123";
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

  # Required for gtk
  services.dbus.packages = [ pkgs.gnome3.dconf ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}

