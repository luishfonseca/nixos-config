{
  stdenv,
  makeWrapper,
  lib,
  bash,
  coreutils,
  findutils,
  colordiff,
}:
stdenv.mkDerivation rec {
  name = "root-diff";
  src = ./.;

  buildInputs = [bash coreutils findutils colordiff];
  nativeBuildInputs = [makeWrapper];
  installPhase = ''
    mkdir -p $out/bin
    cp ${name}.sh $out/bin/${name}
    chmod +x $out/bin/${name}
    wrapProgram $out/bin/${name} --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
