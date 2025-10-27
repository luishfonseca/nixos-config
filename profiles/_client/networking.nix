{profiles, ...}: {
  imports = with profiles; [networkmanager];

  config = {
    programs.captive-browser = {
      enable = true;
      bindInterface = false;
    };
  };
}
