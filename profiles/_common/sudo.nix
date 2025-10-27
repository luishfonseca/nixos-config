{
  security.sudo = {
    enable = true;
    execWheelOnly = true;
    wheelNeedsPassword = true;
    extraConfig = ''
      Defaults lecture="never"
    '';
  };

  user.extraGroups = ["wheel"];
}
