{
  description = "LHF's NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # lunarVim = {
    #   url = "github:LunarVim/LunarVim";
    #   flake = false;
    # };
    # neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-24.05";
    nixos-mailserver.inputs.nixpkgs.follows = "nixpkgs";

    programs-sqlite.url = "github:wamserma/flake-programs-sqlite";
    programs-sqlite.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence/master";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Packages
    kmonad.url = "github:kmonad/kmonad?dir=nix";
    kmonad.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { ... }@args: import ./outputs.nix args;
}
