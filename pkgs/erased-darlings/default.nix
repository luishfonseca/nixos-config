{
  stdenv,
  makeWrapper,
  lib,
  bash,
  rsync,
  ncurses,
  gnused,
  gnugrep,
}:
stdenv.mkDerivation rec {
  name = "erased-darlings";
  src = ./.;

  buildInputs = [bash rsync ncurses gnused gnugrep];
  nativeBuildInputs = [makeWrapper];
  installPhase = ''
    mkdir -p $out/bin
    cp ${name}.sh $out/bin/${name}
    chmod +x $out/bin/${name}
    wrapProgram $out/bin/${name} --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
