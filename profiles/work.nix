{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    thunderbird
    rnix-lsp
    gcc
  ];

  programs.ssh.extraConfig = ''
    Host inesc-nuc
      HostName 146.193.41.141
      User luisfonseca
  '';

  networking.wg-quick.interfaces.gsd = {
    address = [ "10.42.0.11/16" ];
    privateKeyFile = "/etc/wireguard/gsd.key";
    peers = [{
      publicKey = "O/sWbT+agyhq0nywcUny//gQPudTJ8BmKWSy7RUzd1o=";
      allowedIPs = [ "146.193.41.141" ];
      endpoint = "146.193.41.29:51820";
    }];
  };

  lhf.programs.vscode = {
    enable = true;
    extensions = with pkgs.latest.vscode-extensions; [
      mkhl.direnv
      github.copilot
      ms-vscode-remote.remote-ssh
      mvllow.rose-pine
      file-icons.file-icons

      tomoki1207.pdf

      pkgs.vscode-extensions.eamodio.gitlens

      bierner.markdown-mermaid
      bierner.markdown-emoji
      bierner.markdown-checkbox

      ms-vscode.cpptools
      ms-vscode.cmake-tools

      redhat.java
      vscjava.vscode-java-debug
      vscjava.vscode-maven
      vscjava.vscode-java-dependency
      vscjava.vscode-java-test
      sonarsource.sonarlint-vscode

      jnoortheen.nix-ide

      svelte.svelte-vscode

      (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "glassit";
          publisher = "s-nlf-fh";
          version = "0.2.4";
          sha256 = "sha256-YmohKiypAl9sbnmg3JKtvcGnyNnmHvLKK1ifl4SmyQY=";
        };
        buildInputs = [ pkgs.xorg.xprop ];
      })

      (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "vscode-kmonad";
          publisher = "canadaduane";
          version = "0.2.0";
          sha256 = "sha256-dAf8SQ/JkipsnZsSxD4Sipd0hwUGVJrN7+rnnw8+JpA=";
        };
      })
    ];
  };
}
