{
  lib,
  inputs,
  secrets,
  pkgs,
  ...
}: {
  imports = [inputs.agenix.nixosModules.age];

  environment.systemPackages = [pkgs.agenix pkgs.age];

  services.openssh.hostKeys = [];

  age = {
    inherit secrets;
    identityPaths = lib.mkDefault ["/etc/ssh/ssh_host_ed25519_key"];
  };

  persist.local.files = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];
}
