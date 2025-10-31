{profiles, ...}: {
  imports = with profiles; [networkmanager];

  programs.captive-browser = {
    enable = true;
    bindInterface = false;
  };
}
