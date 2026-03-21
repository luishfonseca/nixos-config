{
  stdenv,
  makeWrapper,
  lib,
  bash,
  openssl,
  curl,
  gawk,
  cryptsetup,
  coreutils,
}:
stdenv.mkDerivation rec {
  name = "luks-reboot-prepare";
  src = ./.;

  buildInputs = [
    bash
    openssl
    curl
    gawk
    cryptsetup
    coreutils
  ];
  nativeBuildInputs = [makeWrapper];
  installPhase = ''
    mkdir -p $out/bin
    cp ${name}.sh $out/bin/${name}
    chmod +x $out/bin/${name}
    wrapProgram $out/bin/${name} --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
