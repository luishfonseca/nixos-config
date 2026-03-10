{
  pkg-config,
  libsecret,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage rec {
  pname = "brave-search-mcp-server";
  version = "2.0.72";

  nativeBuildInputs = [pkg-config];
  buildInputs = [libsecret];

  src = fetchFromGitHub {
    owner = "brave";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-9eaExBA+kCZWvEigHbvY9bcp3GrE6pVuVOgCl1Ym3BM=";
  };

  postPatch = ''
    cp ${./package-lock.json} ./package-lock.json
  '';

  npmDepsHash = "sha256-ONGCOv3Sy6V5HJS/xhHOb8wTeh8ytZMU3WqKDdgUnco=";

  meta.mainProgram = "brave-search-mcp-server";
}
