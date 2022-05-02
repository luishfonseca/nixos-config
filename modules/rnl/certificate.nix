{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.rnl.certificate; in
{
  options.lhf.rnl.certificate.enable = mkEnableOption "RNL Certificate";

  config.security.pki.certificateFiles = mkIf cfg.enable (
    let cert = pkgs.fetchurl {
      url = "https://rnl.tecnico.ulisboa.pt/ca/cacert/cacert.pem";
      hash = "sha256-Qg7e7LIdFXvyh8dbEKLKdyRTwFaKSG0qoNN4KveyGwg=";
    }; in [ "${cert}" ]
  );
}
