{
  networking.networkmanager = {
    enable = true;
    dns = "none";
  };

  user.extraGroups = ["networkmanager"];
}
