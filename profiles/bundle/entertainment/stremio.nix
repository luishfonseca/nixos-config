{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    stremio-linux-shell
    mpv
  ];

  hm.xdg.mimeApps = {
    enable = true;
    defaultApplications."audio/x-mpegurl" = "mpv.desktop";
  };
}
