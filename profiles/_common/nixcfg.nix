{inputs, ...}: {
  nix = {
    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      config.flake = inputs.self;
    };

    nixPath = [
      "nixpkgs=${inputs.nixpkgs}"
    ];

    settings = {
      experimental-features = ["nix-command" "flakes"];
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
}
