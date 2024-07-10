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
    extensions = with pkgs.latest.vscode-extensions; [
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
        version = "2.0.2";
        sha256 = "sha256-GTFrZhdd60Yl00YagIbBsRer4NPFwQbofinOfZZm9jw=";
      })

      tomoki1207.pdf

      pkgs.vscode-extensions.eamodio.gitlens

      yzhang.markdown-all-in-one
      bierner.markdown-mermaid
      bierner.markdown-emoji
      bierner.markdown-footnotes

      (buildExtension {
        name = "markdown-sup";
        publisher = "DevHawk";
        version = "1.0.6";
        sha256 = "sha256-I54bDqowSCX8meSAPHsL9lprq86YVewPHUikkXLmuRs=";
      })

      ms-vscode.cpptools
      ms-vscode.cmake-tools
      twxs.cmake

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
        name = "glsl-lsp";
        publisher = "kuba-p";
        version = "0.0.2";
        sha256 = "sha256-MmA73L6fCfQ/KYBzGWDgEdktzDuRonUSppwq9GxuLGY=";
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
