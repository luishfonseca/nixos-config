# Here I create the systems for my machines.

{ self, ... } @ inputs:
let
  inherit (builtins) abort mapAttrs listToAttrs attrValues concatLists readDir;
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

  mkSystem = cfg: let
    system = warnIf (!(cfg ? system))
      "You should define ${cfg.hostName}.system in ./hosts.nix, assuming \"x86_64-linux\""
      (cfg.system or "x86_64-linux");
    pkgs = mkPkgs system;
  in nixosSystem {
    inherit pkgs system;

    modules = let extraArgs = { inherit inputs pkgs cfg; }; in [
      "${./hosts}/${cfg.hostName}/configuration.nix"

      # Set hostname
      { networking.hostName = cfg.hostName; }

      # Enable flakes, should be able to remove this soon...
      ({ pkgs, ... }: { nix = {
        package = pkgs.unstable.nix;
        extraOptions = "experimental-features = nix-command flakes";
      };})
    ] ++ mkModules ./modules extraArgs;
  };
in {
  nixosConfigurations = mapAttrs (hostName: cfg:
    mkSystem (cfg // { inherit hostName user; })
  ) (import ./hosts.nix);
}
