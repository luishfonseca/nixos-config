{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    lhf.stremio-service
  ];
}
