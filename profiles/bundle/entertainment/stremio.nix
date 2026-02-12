{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    pr-stremio.stremio-linux-shell
    mpv
  ];

  hm.xdg.mimeApps = {
    enable = true;
    defaultApplications."audio/x-mpegurl" = "mpv.desktop";
  };
}
