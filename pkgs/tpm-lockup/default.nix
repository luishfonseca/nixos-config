{
  stdenv,
  makeWrapper,
  lib,
  bash,
  jq,
  sbctl,
}:
stdenv.mkDerivation rec {
  name = "tpm-lockup";
  src = ./.;

  buildInputs = [bash jq sbctl];
  nativeBuildInputs = [makeWrapper];
  installPhase = ''
    mkdir -p $out/bin
    cp ${name}.sh $out/bin/${name}
    chmod +x $out/bin/${name}
    wrapProgram $out/bin/${name} --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
