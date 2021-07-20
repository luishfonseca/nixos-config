{ stdenv, lib, fetchFromGitHub, guile, rofi, pkg-config, autoconf-archive, texinfo, autoreconfHook }:

stdenv.mkDerivation rec {
  name = "pinentry-rofi-${version}";
  version = "2.0.3";

  buildInputs = [ guile rofi ];

  nativeBuildInputs = [ pkg-config autoconf-archive texinfo autoreconfHook ];

  src = fetchFromGitHub {
    owner = "plattfot";
    repo = "pinentry-rofi";
    rev = version;
    sha256 = "sha256-EzbeMAhdn9SuSmE+aMHeyuje3s74isIKRDTrFO3bX04=";
  };

  meta = {
    description = "rofi-based pinentry implementation";
    homepage = "https://github.com/plattfot/pinentry-rofi";
    license = lib.licenses.gpl3;
    platforms = lib.platforms.linux;
  };
}
