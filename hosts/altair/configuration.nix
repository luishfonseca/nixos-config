# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, inputs, system, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  profiles = [
    "work"
    "entertainment"
    "note-taking"
  ];

  environment.systemPackages = with pkgs; [
    (chromium.override {
      commandLineArgs = [
        "--force-dark-mode"
        "--enable-features=WebUIDarkMode"
      ];
    })

    volctl
    pavucontrol
    unzip
  ];

  hm.services.flameshot.enable = true;

  programs.steam.enable = true;

  services.physlock.enable = true;

  programs.ssh.askPassword = "${pkgs.my.gnome-ssh-askpass}/bin/gnome-ssh-askpass2";
  lhf.services.ssh = {
    enable = true;
    host.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIACIg+b3uakGCFSOL8XR35jGjZEdX6RYDGuWvdZ3hm4";
    user.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE98aQ0VshDOnylLmZcfEdbuxZllCDtfBYH2786f4nph";
    allowSSHAgentAuth = true;
    preferAskPassword = true;
    manageKnownHosts.enable = true;
    manageSSHAuthKeys = {
      enable = true;
      extraKeys."luis@vega" = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBI51YbPjEZ/NGZ+ibWmyencNqZ1YYX111SIuPUzidGEMaT0oUYRPdLmRczgW3HPCoNpgV9Png0OFivDCJbPYhXo=";
    };
  };

  lhf.services.wallpaper = {
    enable = true;
    images = (lib.mapAttrsToList
      (name: hash: pkgs.fetchurl {
        url = "https://github.com/rose-pine/wallpapers/raw/main/${name}";
        sha256 = hash;
      })
      {
        "beachhouses.jpg" = "sha256-rFJFEBg3RbJQ9LFG0/ZNuqts2H4bMw7bY7Rf64XO+Gg=";
        "bench.JPG" = "sha256-Vw6HIfZF6e9CPNZR8m5Iy1YeeVHH/upb12oMN8r5ics=";
        "field.jpg" = "sha256-OLLqugzrFxFj9KnQr3X15zLO1Xt4J0ndIoFQtFjCY3k=";
        "flower.jpg" = "sha256-A83dUw3QT7GpWGSV+JY7F+kU38CNk5uQrzFwyL5yFdE=";
        "oceandrone1.JPG" = "sha256-P0fDOjNYphPgKPI3HG9BUn3Sw89HQFBH/EltCjOHB20=";
        "oceandrone2.JPG" = "sha256-uPeMZPKaL0C2htuxJ0B+0nO0dsPiYtfWhFxsvnvY3J4=";
        "pointoverhead.jpg" = "sha256-Sk1DVNxM3t0WhBrPQT76LgP6j3mZ6frrF5rJQakOHL4=";
        "rocks.jpg" = "sha256-8QA6Cn5r0nvLYjF4AzfgWkdsWV7Ci3ve4ta94VAu1I4=";
        "roses.jpg" = "sha256-/5mtqvnbLZ7/sLM+EduPJHHia3w0iTmbp8q3/V5idEM=";
        "seals.jpg" = "sha256-WVzSfRZRqcHM58Gxh5SThaIfl7fLLwokcWIXQh/buPA=";
        "seaslug.jpg" = "sha256-uxQkOABlP34ajEreoWI32iN8pgt2faYJumEBQYSDk3s=";
      });
    effects.enable = true;
  };


  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Lisbon";

  networking.domain = "in.lhf.pt";

  lhf.services.dnsovertlsProxy = {
    enable = true;
    name = "ns.lhf.pt";
    ip = "146.59.158.114";
    cache = 3600;
  };

  environment.variables.VDPAU_DRIVER = "va_gl";

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      vaapiIntel
      libvdpau-va-gl
      intel-media-driver
    ];
  };

  networking.networkmanager.enable = true;
  hm.services.network-manager-applet.enable = true;
  networking.networkmanager.dns = "none";

  services.tailscale.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      disableWhileTyping = true;
    };
  };

  lhf.kbd = {
    enable = true;
    package = inputs.kmonad.packages.${system}.kmonad;
    kbdDir = ./kbds;
  };

  lhf.powerSaving.enable = true;
  lhf.tmpfsRoot.enable = true;
  lhf.theme.enable = true;

  programs.light.enable = true;

  lhf.programs.htop.enable = true;
  lhf.programs.tmux.enable = true;
  lhf.programs.git.enable = true;
  lhf.programs.kitty.enable = true;
  lhf.programs.rofi.enable = true;
  lhf.programs.discord.enable = true;

  lhf.programs.bspwm = {
    enable = true;
    swallow = false;
    transparency = true;
    colors = {
      background = "#1f1d2e";
      background-alt = "#403d52";
      foreground = "#e0def4";
      accent = "#9ccfd8";
      disabled = "#6e6a86";
    };
    polybar = {
      enable = true;
      top = {
        enable = true;
        left = [ "xwindow" ];
        right = [ "date" "battery" ];
      };
      bottom = {
        enable = true;
        left = [ "tray" ];
        center = [ "bspwm" ];
        right = [ "xkeyboard" "memory" "cpu" "wlan" "eth" ];
      };
    };
    sxhkd.binds = {
      "Return" = "kitty"; # terminal emulator
      "space" = "rofi -show drun"; # program launcher
      "shift + space" = "rofi -show run"; # command launcher
      "alt + {q,r}" = "bspc {quit,wm -r}"; # quit/restart bspwm
      "{_,shift + }w" = "bspc node -{c,k}"; # close and kill
      "m" = "bspc desktop -l next"; # alternate between the tiled and monocle layout
      "g" = "bspc node -s biggest.window"; # swap the focused window with the biggest window
      "{t,shift + t,s,f}" = "bspc node -t {tiled,pseudo_tiled,floating,fullscreen}"; # set the window state
      "ctrl + {m,x,y,z}" = "bspc node -g {marked,locked,sticky,private}"; # set the window flags
      "{_,shift + }{h,j,k,l}" = "bspc node -{f,s} {west,south,north,east}"; # focus and swap
      "{p,b,comma,period}" = "bspc node -f @{parent,brother,first,second}"; # focus tree
      "{_,shift + }c" = "bspc node -f {next,prev}.local.!hidden.window"; # focus next/prev window
      "{grave,Tab}" = "bspc {node,desktop} -f last"; # focus last node/desktop
      "{_,shift + }{1-9,0}" = "bspc {desktop -f,node -d} '^{1-9,10}'"; # focus or send to desktop
      "ctrl + {h,j,k,l}" = "bspc node -p {west,south,north,east}"; # preselect
      "ctrl + {1-9}" = "bspc node -o 0.{1-9}"; # preselect the ratio
      "ctrl + space" = "bspc node -p cancel"; # cancel the preselection
      "alt + {h,j,k,l}" = "bspc node -z {left -20 0,bottom 0 20,top 0 -20,right 20 0}"; # expand
      "alt + shift + {h,j,k,l}" = "bspc node -z {right -20 0,top 0 20,bottom 0 -20,left 20 0}"; # shrink
      "{Left,Down,Up,Right}" = "bspc node -v {-20 0,0 20,0 -20,20 0}"; # move floating window
    };
  };

  lhf.services.picom.enable = true;

  lhf.programs.virtManager.enable = true;

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  lhf.shell.fish = {
    enable = true;
    starship.enable = true;
    anyNixShell.enable = true;
    direnv.enable = true;
  };

  lhf.shell.dash = {
    enable = true;
    isSystemDefault = true;
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  hm.services.blueman-applet.enable = true;

  # lhf.programs.gpg.enable = true;
  # lhf.programs.gpg.sshKeys = [ "DB4E50598EBC42BC801BBEC6C39A9A399FD27081" ];

  user.hashedPassword = "$6$SJ8UawnwW$LoL1DmZ4J8ade7b/n8h8O9Q44w6JyB5JKMXk2cBLz2D9SQJRZkfsd4XhAQ2.J8Gl2coYGAM1ls/Un5kOXSoT/0";
  users.mutableUsers = false;

  user.extraGroups = [ "input" "uinput" "video" ];

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
    checkReversePath = "loose";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}

