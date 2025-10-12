{
  stdenv,
  makeWrapper,
  lib,
  bash,
  jq,
  lhf,
}:
stdenv.mkDerivation rec {
  name = "tpm-lockup";
  src = ./.;

  buildInputs = [bash jq lhf.sbctl];
  nativeBuildInputs = [makeWrapper];
  installPhase = ''
    mkdir -p $out/bin
    cp ${name}.sh $out/bin/${name}
    chmod +x $out/bin/${name}
    wrapProgram $out/bin/${name} --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
