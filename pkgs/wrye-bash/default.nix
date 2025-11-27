{pkgs}: let
  games = "$HOME/games";

  src = pkgs.fetchFromGitHub {
    owner = "wrye-bash";
    repo = "wrye-bash";
    rev = "7e368d628235e6d6a54f21b1a910b625ce9fa51b";
    hash = "sha256-diGsxV5t/pmMAibt7T7hgu5AwVd2XcUdwLfEwP1nNws=";
  };
in
  pkgs.writeShellApplication {
    name = "wrye-bash";
    runtimeInputs = with pkgs; [
      p7zip
      binutils
      hicolor-icon-theme
      xdg-utils
      (python3.withPackages (ps:
        with ps; [
          chardet
          lz4
          reflink
          vdf
          wxpython
          pyyaml
          pygit2
          lxml
          pymupdf
          packaging
          requests
          websocket-client

          rsync
        ]))
    ];
    text = ''
      set -euo pipefail
      dest="${games}/mods/wrye-bash/Mopy"
      mkdir -p "$dest"

      rsync -a --ignore-existing "${src}/Mopy/" "$dest/"
      chmod 755 -R "$dest"

      cd "$dest"
      python3 "Wrye Bash Launcher.pyw"
    '';
  }
