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
    xkbOptions = "ralt:compose,caps:escape";
    xkbVariant = "colemak_dh";
    autoRepeatDelay = 200;
    autoRepeatInterval = 25;
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    
    displayManager.defaultSession = "none+bspwm";

    windowManager.bspwm.enable = true; 
    displayManager.lightdm.enable = true;

    displayManager.lightdm.greeters.mini = {
      enable = true;
      user = "luis";
    };
  };

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Define a user account.
  nix.trustedUsers = [ "root" "@wheel" ];
  users.users.luis = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  # home.users.luis.xdg.enable = true;

  environment = {
    variables = {
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_BIN_HOME = "$HOME/.local/bin";
    };

    systemPackages = with pkgs; [
      neovim
      git
      wget
      firefox
      alacritty
    ];
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

