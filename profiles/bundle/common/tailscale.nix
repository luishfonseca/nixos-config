{
  config,
  lib,
  ...
}: {
  services.tailscale = lib.mkMerge [
    {
      enable = true;
      openFirewall = true;
      extraSetFlags = ["--operator=${config.user.name}"];
    }
    (lib.mkIf (builtins.hasAttr "tailscale-auth-key" config.sops.secrets) {
      authKeyFile = config.sops.secrets.tailscale-auth-key.path;
      authKeyParameters = {
        ephemeral = false;
        preauthorized = true;
      };
      extraUpFlags = ["--advertise-tags=tag:fleet,tag:${config.networking.hostName}"];
    })
  ];
}
