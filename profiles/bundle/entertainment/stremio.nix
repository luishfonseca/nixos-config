{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    lhf.stremio-service
    mpv
  ];

  hm.xdg.mimeApps = {
    enable = true;
    defaultApplications."audio/x-mpegurl" = "mpv.desktop";
  };
}
