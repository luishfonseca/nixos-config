{
  stdenv,
  makeWrapper,
  lib,
  bash,
  curl,
  hostname,
  jq,
}:
stdenv.mkDerivation rec {
  name = "write-initrd-tailscale-key";
  src = ./.;

  buildInputs = [
    bash
    curl
    hostname
    jq
  ];
  nativeBuildInputs = [makeWrapper];
  installPhase = ''
    mkdir -p $out/bin
    cp ${name}.sh $out/bin/${name}
    chmod +x $out/bin/${name}
    wrapProgram $out/bin/${name} --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
