{
  inputs,
  config,
  pkgs,
  profiles,
  modulesPath,
  ...
}: {
  imports = with profiles; [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.network-unlock.nixosModules.default
    bundle.server
  ];

  # deneb:WVbL9VL8s2wXdDz+rV+ZVO8zh4vO1CCgTLfa7q9FGuI=
  pasta.endpoints.cache = "http://deneb:5000";
  services.nix-serve = {
    enable = true;
    package = pkgs.nix-serve-ng;
    secretKeyFile = config.sops.secrets.binary-cache-key.path;
  };

  services.openssh.extraConfig = let
    registry = pkgs.writeText "registry.json" (builtins.toJSON {
      version = 2;
      flakes = [
        {
          from = {
            type = "indirect";
            id = "nixpkgs";
          };
          to = {
            type = "path";
            inherit (pkgs) path;
          };
        }
      ];
    });

    nixConf = pkgs.writeText "nix.conf" ''
      experimental-features = nix-command flakes
      flake-registry = file://${registry}
    '';
  in ''
    Match User builder
      ForceCommand ${pkgs.writeShellScript "builder-sandbox" ''
      exec ${pkgs.bubblewrap}/bin/bwrap \
        --die-with-parent \
        --unshare-all \
        --share-net \
        --dev /dev \
        --proc /proc \
        --tmpfs /tmp \
        --bind /nix/var /nix/var \
        --bind /home/builder /home/builder \
        --ro-bind /nix/store /nix/store \
        --ro-bind /etc/passwd /etc/passwd \
        --ro-bind /etc/group /etc/group \
        --ro-bind ${nixConf} /etc/nix/nix.conf \
        --clearenv \
        --setenv PATH ${pkgs.lib.makeBinPath (with pkgs; [bash coreutils nix])} \
        -- bash ''${SSH_ORIGINAL_COMMAND:+-c "$SSH_ORIGINAL_COMMAND"}
    ''}
  '';

  # The daemon won't substitute if the client thinks it's offline
  # Thus --share-net is required, but this firewall blocks all traffic
  networking.nftables = {
    enable = true;
    tables.builder-sandbox = {
      family = "inet";
      content = ''
        chain output {
          type filter hook output priority 0; policy accept;
          meta skuid != ${toString config.users.users.builder.uid} accept
          reject
        }
      '';
    };
  };

  programs.ssh.extraConfig = ''
    Host albireo-a
      IdentitiesOnly yes
      IdentityFile ${config.sops.secrets.ssh_host_ed25519.path}
      User builder
  '';

  nix = {
    settings = {
      allowed-users = ["builder"];
      trusted-public-keys = ["github-ci-runner:fzPtqB5rudN+PwaT3opbYgRyL2jXD8QlOfW02GFccfs="];
      secret-key-files = config.sops.secrets.binary-cache-key.path;
    };
    buildMachines = [
      {
        hostName = "albireo-a";
        systems = ["x86_64-linux" "i686-linux"];
        protocol = "ssh-ng";
        maxJobs = 2;
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel"];
        mandatoryFeatures = [];
      }
    ];
    distributedBuilds = true;
  };

  users.groups.builder = {gid = 1400;};
  users.users.builder = {
    isNormalUser = true;
    group = "builder";
    uid = 1400;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMw4W1SN63EFsyIunxa3IXnqCgpsQ0NS/xSUyFU5kWZP github-ci-runner"
    ];
  };

  networkUnlock = rec {
    server = {
      enable = true;
      openFirewall = true;
      internal = "100.105.35.24";
      external = "10.0.0.148"; # oracle cloud does nat 1:1
      public = "158.178.156.3";
    };
    client = {
      enable = true;
      units = ["tailscaled.service"];
      self = {
        inherit (server) internal public;
      };
      peer = {
        internal = "100.123.137.111";
        public = "178.104.72.93";
      };
      luks = {
        crypt = "root_crypt";
        key = "/recovery/root.key";
      };
    };
  };

  lhf.boot.disk.devices = [
    {
      path = "/dev/sda";
      size = "100%";
    }
  ];

  boot = {
    loader.systemd-boot.configurationLimit = 3;
    initrd.systemd.network = {
      enable = true;
      networks."99-dhcp" = {
        matchConfig.Type = "ether";
        networkConfig.DHCP = "yes";
      };
    };
  };

  networking.useNetworkd = true;

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.11";
}
