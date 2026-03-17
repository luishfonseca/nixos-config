{
  config,
  lib,
  ...
}: let
  hasTailscaleAuthKey = builtins.hasAttr "tailscale-auth-key" config.sops.secrets;
in {
  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = lib.mkIf hasTailscaleAuthKey config.sops.secrets.tailscale-auth-key.path;
    authKeyParameters = {
      ephemeral = false;
      preauthorized = true;
    };
    extraUpFlags = ["--advertise-tags=tag:fleet,tag:${config.networking.hostName}"];
  };
}
