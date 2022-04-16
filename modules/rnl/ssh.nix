{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.lhf.rnl.ssh; in
{
  options.lhf.rnl.ssh = with types; {
    enable = mkEnableOption "RNL SSH Config";
    rnladmin = mkOption { type = str; };
  };

  config.programs.ssh.extraConfig = mkIf cfg.enable ''
    CanonicalizeHostname yes
    CanonicalDomains rnl.tecnico.ulisboa.pt
    CanonicalizeMaxDots 0

    Match originalhost lab*,!lab*.rnl.tecnico.ulisboa.pt
      HostName dolly.rnl.tecnico.ulisboa.pt
      User root
      RemoteCommand ssh %n
      ForwardAgent no
      RequestTTY yes

    Match canonical host="*.rnl.tecnico.ulisboa.pt"
      User root
      SetEnv RNLADMIN=luis.fonseca
      ServerAliveInterval 60

    Host *.rnl.tecnico.ulisboa.pt *.rnl.ist.utl.pt
      User root
      SetEnv RNLADMIN=${cfg.rnladmin}
      ServerAliveInterval 60
  '';
}
