{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    thunderbird
    nil
    gcc
    python3Packages.autopep8
  ];

  programs.ssh.extraConfig = ''
    Host inesc-nuc
      HostName 146.193.41.141
      User luisfonseca
  '';

  networking.wg-quick.interfaces.gsd = {
    address = ["10.42.0.11/16"];
    privateKeyFile = "/etc/wireguard/gsd.key";
    peers = [
      {
        publicKey = "O/sWbT+agyhq0nywcUny//gQPudTJ8BmKWSy7RUzd1o=";
        allowedIPs = ["146.193.41.141"];
        endpoint = "146.193.41.29:51820";
      }
    ];
  };

  lhf.programs.vscode = let
    buildExtension = {
      name,
      publisher,
      version,
      sha256,
      buildInputs ? [],
    }:
      pkgs.vscode-utils.buildVscodeMarketplaceExtension {
        inherit buildInputs;
        mktplcRef = {
          inherit name publisher version sha256;
        };
      };
  in {
    enable = true;
    extensions = with pkgs.unstable.vscode-extensions; [
      mkhl.direnv
      github.copilot
      ms-vscode-remote.remote-ssh
      mvllow.rose-pine
      file-icons.file-icons
      gruntfuggly.todo-tree

      streetsidesoftware.code-spell-checker
      (buildExtension {
        name = "code-spell-checker-portuguese";
        publisher = "streetsidesoftware";
        version = "1.0.5";
        sha256 = "sha256-Cs1YJRwDGbTs67nF12of/KWKjd6NEN6TyFi0AZKCdz4=";
      })

      tomoki1207.pdf

      pkgs.vscode-extensions.eamodio.gitlens

      yzhang.markdown-all-in-one
      bierner.markdown-mermaid
      bierner.markdown-emoji
      (buildExtension {
        name = "markdown-footnotes";
        publisher = "bierner";
        version = "0.1.1";
        sha256 = "sha256-h/Iyk8CKFr0M5ULXbEbjFsqplnlN7F+ZvnUTy1An5t4=";
      })
      (buildExtension {
        name = "markdown-sup";
        publisher = "DevHawk";
        version = "1.0.6";
        sha256 = "sha256-I54bDqowSCX8meSAPHsL9lprq86YVewPHUikkXLmuRs=";
      })

      ms-vscode.cpptools
      ms-vscode.cmake-tools

      ms-python.python

      alygin.vscode-tlaplus

      ms-dotnettools.csharp
      zxh404.vscode-proto3

      jnoortheen.nix-ide

      rust-lang.rust-analyzer
      bungcip.better-toml

      redhat.java
      vscjava.vscode-maven

      golang.go

      (buildExtension {
        name = "shader-toy";
        publisher = "stevensona";
        version = "0.11.2";
        sha256 = "sha256-gsjAxD40sf35Wop27crkJq4Wov5R62UTEs3n5prGVhw=";
      })

      (buildExtension {
        name = "glsl-lsp";
        publisher = "kuba-p";
        version = "0.0.2";
        sha256 = "sha256-MmA73L6fCfQ/KYBzGWDgEdktzDuRonUSppwq9GxuLGY=";
      })

      (buildExtension {
        name = "glassit";
        publisher = "s-nlf-fh";
        version = "0.2.4";
        sha256 = "sha256-YmohKiypAl9sbnmg3JKtvcGnyNnmHvLKK1ifl4SmyQY=";
        buildInputs = [pkgs.xorg.xprop];
      })

      (buildExtension {
        name = "vscode-kmonad";
        publisher = "canadaduane";
        version = "0.2.0";
        sha256 = "sha256-dAf8SQ/JkipsnZsSxD4Sipd0hwUGVJrN7+rnnw8+JpA=";
      })
    ];
  };
}
