{
  inputs,
  secrets,
  config,
  ...
}: {
  assertions = [
    {
      assertion = config.services.userborn.enable;
      message = "Userborn must be enabled to make sops use systemd activation";
    }
  ];

  imports = [inputs.sops-nix.nixosModules.sops];

  sops = {
    inherit secrets;
    defaultSopsFormat = "binary";
    age.keyFile = "/local/age.key";
  };
}
