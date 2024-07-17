{
  stdenv,
  makeWrapper,
  writeScript,
  bash,
  toybox,
  findutils,
  colordiff,
}:
stdenv.mkDerivation rec {
  name = "root-diff";
  src = ./.;

  buildInputs = [bash];
  nativeBuildInputs = [makeWrapper];
  installPhase = let
    root-diff = writeScript "root-diff" ''
      #!${bash}/bin/bash

      if [ "$EUID" -ne 0 ]; then
          echo "Please run as root"
          exit
      fi

      ${findutils}/bin/find '/' -mount -path '/nix' -prune -o -type f |
        sort |
        ${toybox}/bin/xargs ${toybox}/bin/crc32 |
        diff -u /pst/local/root-crc.txt - |
        ${colordiff}/bin/colordiff |
        less -R
    '';
  in ''
    mkdir -p $out/bin
    cp ${root-diff} $out/bin/${name}
    chmod +x $out/bin/${name}
  '';
}
