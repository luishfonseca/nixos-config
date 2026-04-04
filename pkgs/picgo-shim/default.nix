{
  pkgs,
  lib,
}:
pkgs.buildNpmPackage {
  pname = "picgo-shim";
  version = "2.0.3";

  src = lib.cleanSource ./.;
  npmDepsHash = "sha256-5SZf5VHFvKkw4BhbsmEbJKi4+ZFe8zh+aIf9haSJ10w=";
  dontNpmBuild = true;

  nativeBuildInputs = [pkgs.makeWrapper];
  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/bin
    cp -r node_modules $out/lib/node_modules
    cp server.js $out/lib/server.js

    makeWrapper ${pkgs.nodejs}/bin/node $out/bin/picgo-server \
      --add-flags "$out/lib/server.js" \
      --set NODE_PATH "$out/lib/node_modules"

    runHook postInstall
  '';

  meta.mainProgram = "picgo-server";
}
