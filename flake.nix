{
  description = "LHF's NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-latest.url = "github:NixOS/nixpkgs/master";

    lunarVim = { url = "github:LunarVim/LunarVim"; flake = false; };
    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = { ... } @ args: import ./outputs.nix args;
}
