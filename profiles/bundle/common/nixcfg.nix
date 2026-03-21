{
  inputs,
  config,
  ...
}: {
  nix = {
    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      config.flake = inputs.self;
    };

    nixPath = [
      "nixpkgs=${inputs.nixpkgs}"
    ];

    checkConfig = false;
    extraOptions = ''
      include ${config.sops.templates.nix-access-tokens.path}
    '';

    settings = {
      experimental-features = ["nix-command" "flakes"];
      allowed-users = ["root" config.user.name];
      auto-optimise-store = true;
      sandbox = true;
    };

    gc = {
      dates = "weekly";
      options = "--delete-older-than 30d";
      automatic = true;
      persistent = true;
    };
  };

  sops.templates.nix-access-tokens = {
    mode = "0660";
    group = "wheel";
    content = ''
      access-tokens = github.com=${config.sops.placeholder.nix-github-token}
    '';
  };
}
