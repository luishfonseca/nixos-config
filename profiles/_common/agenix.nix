{
  inputs,
  secrets,
  pkgs,
  ...
}: {
  imports = [inputs.agenix.nixosModules.age];

  environment.systemPackages = [pkgs.agenix pkgs.age];

  age = {
    inherit secrets;
    identityPaths = ["/local/etc/ssh/ssh_host_ed25519_key"];
  };
}
