{
  stdenv,
  lib,
  fetchFromGitHub,
  bash,
  wmctrl,
  graphicsmagick,
  feh,
  gnused,
  coreutils,
  gnugrep,
  makeWrapper,
}:
stdenv.mkDerivation {
  pname = "feh-blur";
  version = "v1";
  src = fetchFromGitHub {
    owner = "rstacruz";
    repo = "feh-blur-wallpaper";
    rev = "fe664c946b417e884c44227781abb3c78d9c6206";
    sha256 = "sha256-w6fN7mkH7iCpjR7QzH7ZJXDSPBS88agHZ3SDFgFVZ+4=";
  };
  buildInputs = [bash wmctrl graphicsmagick feh gnused coreutils gnugrep];
  nativeBuildInputs = [makeWrapper];
  installPhase = ''
    mkdir -p $out/bin
    cp feh-blur $out/bin/feh-blur
    sed -i "s/source \"\$HOME\/.fehbg\"//" $out/bin/feh-blur
    sed -i "s/exit 1/exit/g" $out/bin/feh-blur
    sed -i "s/sleep \"\$POLL_INTERVAL\"/exit/g" $out/bin/feh-blur
    sed -i "s/blank=\"\$(is_blank && echo 1 || echo 0)\"/blank=0/" $out/bin/feh-blur
    wrapProgram $out/bin/feh-blur \
      --prefix PATH : ${lib.makeBinPath [bash wmctrl graphicsmagick feh gnused coreutils gnugrep]}
  '';
}
