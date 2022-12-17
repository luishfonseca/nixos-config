{ config, options, lib, pkgs, inputs, ... }:

{
  environment.variables.NIXPKGS_ALLOW_UNFREE = "1";
  nix = {
    nixPath = [
      "nixpkgs=${inputs.nixpkgs-unstable}"
    ];
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      sandbox = true;
    };
    gc = {
      dates = "weekly";
      automatic = true;
      persistent = true;
    };
  };
  programs.command-not-found.enable = false;
}
