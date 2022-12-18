{ stdenv
, lib
, fetchFromGitHub
, xdo
, xdotool
, xorg
, psmisc
, makeWrapper
}:
stdenv.mkDerivation {
  pname = "pidswallow";
  version = "2.0";
  src = fetchFromGitHub {
    owner = "Liupold";
    repo = "pidswallow";
    rev = "c921b96536d80a711bca976a9795fff7d7fec167";
    sha256 = "sha256-bO4loVVOZfqXtk8TX7hTCad+xpibs1V8ZKNW6YEC/7k=";
  };
  buildInputs = [ xdo xdotool xorg.xprop xorg.xev psmisc ];
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp pidswallow $out/bin/pidswallow
    wrapProgram $out/bin/pidswallow \
      --prefix PATH : ${lib.makeBinPath [ xdo xdotool xorg.xprop xorg.xev psmisc ]}
  '';
}
