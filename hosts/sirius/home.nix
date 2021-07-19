{ pkgs, config, ... }:

{

  programs = {
    ssh = {
      enable = true;
      extraConfig = ''
        Match host * exec "gpg-connect-agent UPDATESTARTUPTTY /bye
      '';
    };

    gpg.enable = true;
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };

  xdg = {
    enable = true;
    configFile = {
      "sxhkd".source = ../../config/sxhkd;
      "bspwm" = { source = ../../config/bspwm; recursive = true; };
    };
  };

  home.file."${config.programs.gpg.homedir}/sshcontrol".text = ''
    B155DE05293E0A22B220AB1F8D3414A3E7DED3CF
  '';
}
