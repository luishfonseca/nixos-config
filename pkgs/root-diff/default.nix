{
  stdenv,
  makeWrapper,
  lib,
  bash,
  toybox,
  findutils,
  colordiff,
}:
stdenv.mkDerivation rec {
  name = "root-diff";
  src = ./.;

  buildInputs = [bash findutils colordiff];
  nativeBuildInputs = [makeWrapper];
  installPhase = ''
    mkdir -p $out/bin
    cp ${toybox}/bin/crc32 $out/bin
    cp ${name}.sh $out/bin/${name}
    chmod +x $out/bin/${name}
    wrapProgram $out/bin/${name} --prefix PATH : ${lib.makeBinPath buildInputs}:$out/bin
  '';
}
