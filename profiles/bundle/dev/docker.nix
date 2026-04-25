{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
      daemon.settings.dns = ["1.1.1.1" "1.0.0.1"];
    };
  };
}
