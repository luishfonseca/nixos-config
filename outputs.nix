# Here I create the systems for my machines.

{ self, ... } @ inputs:
let
  inherit (builtins) abort mapAttrs listToAttrs attrValues concatLists readDir;
  inherit (inputs.flake-utils.lib) eachDefaultSystem;
  inherit (inputs) nixpkgs nixpkgs-unstable nixpkgs-latest; 
  inherit (nixpkgs.lib) nixosSystem hasSuffix hasPrefix warnIf;

  # Primary user account
  user = "luis";

  # Makes unstable acessible through pkgs.unstable, same for latest.
  pkg-sets = final: prev: let args = {
    system = final.system;
    config.allowUnfree = true;
  }; in {
    unstable = import nixpkgs-unstable args;    
    latest = import nixpkgs-latest args;    
  };

  mkPkgs = system: import nixpkgs {
    inherit system;
    overlays = [ pkg-sets ];
    config.allowUnfree = true;
  };

  # Makes a list of all the modules in a folder.
  mkModules = dir: extraArgs: concatLists (attrValues (mapAttrs (n: t:
    let path = "${dir}/${n}";
    in if t == "regular" && hasSuffix ".nix" n && !(hasPrefix "_" n) then [ 
      # Inject extra args here instead of in _module.args.
      ({ ... } @ args: (import path) (args // extraArgs))
    ]
    else if t == "directory" then mkModules path extraArgs
    else []
  ) (readDir dir)));

  mkSystem = system: hostName: let pkgs = mkPkgs system; in nixosSystem {
    inherit system pkgs;

    modules = let extraArgs = { inherit inputs pkgs user; }; in [
      "${./hosts}/${hostName}/configuration.nix"

      # Set hostname
      { networking.hostName = hostName; }

      # Enable flakes, should be able to remove this soon...
      ({ pkgs, ... }: { nix = {
        package = pkgs.unstable.nix;
        extraOptions = "experimental-features = nix-command flakes";
      };})
    ] ++ mkModules ./modules extraArgs;
  };
in eachDefaultSystem (system: { packages = {
  nixosConfigurations = mapAttrs (hostName: t:
    if t == "directory" then
      mkSystem system hostName
    else abort "./hosts/${hostName} should be a directory"
  ) (readDir ./hosts);
};})
