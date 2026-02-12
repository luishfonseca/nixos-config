{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    cmake
    gnumake
    clang
    lld
  ];
}
