# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  services.physlock.enable = true;

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

  networking.nameservers = [ "1.0.0.1" "1.1.1.1" ];
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "none";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    earlySetup = true;
    useXkbConfig = true;
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "colemak_dh";
    xkbOptions = "ralt:compose";
    libinput.touchpad.naturalScrolling = true;
    libinput.touchpad.disableWhileTyping = true;
  };

  lhf.powerSaving.enable = true;
  lhf.tmpfsRoot.enable = true;

  lhf.programs.vscode = {
    enable = true;
    extensions = with pkgs.latest.vscode-extensions; [
      mkhl.direnv
      github.copilot
      mvllow.rose-pine
      file-icons.file-icons

      tomoki1207.pdf

      eamodio.gitlens

      bierner.markdown-mermaid
      bierner.markdown-emoji
      bierner.markdown-checkbox

      ms-vscode.cpptools

      jnoortheen.nix-ide

      (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "glassit";
          publisher = "s-nlf-fh";
          version = "0.2.4";
          sha256 = "sha256-YmohKiypAl9sbnmg3JKtvcGnyNnmHvLKK1ifl4SmyQY=";
        };
        buildInputs = [ pkgs.xorg.xprop ];
      })
    ];
  };

  environment.systemPackages = with pkgs; [
    rnix-lsp
    gcc
  ];

  lhf.programs.neovim.enable = false;
  lhf.programs.htop.enable = true;
  lhf.programs.tmux.enable = true;
  lhf.programs.git.enable = true;
  lhf.programs.kitty.enable = true;
  lhf.programs.rofi.enable = true;
  lhf.programs.discord.enable = true;

  lhf.programs.bspwm = {
    enable = true;
    swallow = true;
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
        left.modules = [ "xwindow" ];
        right.modules = [ "date" "battery" ];
      };
      bottom = {
        enable = true;
        left.tray = true;
        center.modules = [ "bspwm" ];
        right.modules = [ "xkeyboard" "memory" "cpu" "wlan" "eth" ];
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

  virtualisation.libvirtd.enable = true;
  lhf.programs.virtManager.enable = true;

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

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  users.users.luis.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII9M6O9ZBXm95eIkqdDk6RWEmHwA0oZXN4TEtfY2dtIR"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHgnSKa8CXwWeqAxnkWBASF2tTJ33VylGWI68DAftIsQ"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKFlJJH6flIuAxeF68lXgfaXRJkcsGD0IChY5P/0Wajr"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKYZF9DXj0XZ7be9Rc0yC3WKhr30Xbn1kqjbzWBLcC6K"
  ];

  lhf.programs.gpg.enable = true;
  lhf.programs.gpg.sshKeys = [ "DB4E50598EBC42BC801BBEC6C39A9A399FD27081" ];

  users.users.luis.hashedPassword =
    "$6$SJ8UawnwW$LoL1DmZ4J8ade7b/n8h8O9Q44w6JyB5JKMXk2cBLz2D9SQJRZkfsd4XhAQ2.J8Gl2coYGAM1ls/Un5kOXSoT/0";
  users.mutableUsers = false;

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
  system.stateVersion = "21.11"; # Did you read the comment?
}

