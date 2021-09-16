# modules/system/rnl/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# RNL (my workplace) related configuration.

{ pkgs, config, ... }:
let
  hosts = {
    altair.address = [ "192.168.20.34/24" "fd92:3315:9e43:c490::34/64" ];
    sirius.address = [ "192.168.20.46/24" "fd92:3315:9e43:c490::46/64" ];
  };
in {
  # Setup wireguard interface
  networking.wg-quick.interfaces = {
    rnl = let fwmark = "765";
    in {
      inherit (hosts.${config.hostName}) address;
      dns = [ "193.136.164.1" "193.136.164.2" ];
      privateKeyFile = "/etc/nixos/secrets/wg-privkey";
      table = fwmark;
      postUp = ''
        ${pkgs.wireguard-tools}/bin/wg set rnl fwmark ${fwmark}
        ${pkgs.iproute2}/bin/ip rule add not fwmark ${fwmark} table ${fwmark}
        ${pkgs.iproute2}/bin/ip -6 rule add not fwmark ${fwmark} table ${fwmark}
      '';
      postDown = ''
        ${pkgs.iproute2}/bin/ip rule del not fwmark ${fwmark} table ${fwmark}
        ${pkgs.iproute2}/bin/ip -6 rule del not fwmark ${fwmark} table ${fwmark}
      '';
      peers = [{
        publicKey = "g08PXxMmzC6HA+Jxd+hJU0zJdI6BaQJZMgUrv2FdLBY=";
        endpoint = "193.136.164.211:34266";
        allowedIPs = [
          "193.136.164.0/24"
          "193.136.154.0/24"
          "10.16.64.0/18"
          "2001:690:2100:80::/58"
          "193.136.128.24/29"
          "146.193.33.81/32"
          "192.168.154.0/24"
        ];
      }];
    };
  };

  # Use RNL's CA certificate
  security.pki.certificateFiles = let
    cert = pkgs.fetchurl {
      url = "https://rnl.tecnico.ulisboa.pt/ca/cacert/cacert.pem";
      hash = "sha256-Qg7e7LIdFXvyh8dbEKLKdyRTwFaKSG0qoNN4KveyGwg=";
    };
  in [ "${cert}" ];
}
