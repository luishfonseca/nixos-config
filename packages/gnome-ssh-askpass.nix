{ lib, stdenv, pkg-config, openssh, gtk2, gtk3 }:
stdenv.mkDerivation rec {
  inherit (openssh) src version;
  pname = "gnome-ssh-askpass";

  buildInputs = [
    pkg-config
    gtk2
    gtk3
  ];

  doCheck = false;
  dontConfigure = true;

  buildPhase = ''
    cd contrib
    make ${pname}2 ${pname}3
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv -t $out/bin ${pname}2 ${pname}3
  '';
}
