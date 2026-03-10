{
  lib,
  pkgs,
  ...
}: {
  imports = lib.lhf.flattenLeaves (lib.lhf.rakeNixLeaves ./.);

  environment.systemPackages = with pkgs; [
    curl
    jq

    cmake
    gnumake
    clang
    lld
  ];
}
