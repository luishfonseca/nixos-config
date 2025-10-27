{
  inputs,
  secrets,
  ...
}: {
  imports = [inputs.sops-nix.nixosModules.sops];

  sops = {
    inherit secrets;
    defaultSopsFormat = "binary";
    age.keyFile = "/nix/pst/age.key";
  };
}
