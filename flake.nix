{
  description = "LHF's NixOS config";

  inputs = {
    nixpkgs.url =          "github:NixOS/nixpkgs/nixos-21.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-latest.url =   "github:NixOS/nixpkgs/master";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

  };

  outputs = { ... } @ args: import ./outputs.nix args;
}
