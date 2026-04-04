{
  pkgs,
  lib,
}:
pkgs.buildNpmPackage {
  pname = "picgo-shim";
  version = "2.0.3";

  src = lib.cleanSource ./.;
  npmDepsHash = "sha256-SgzfuytOzr+Nshp0TlutvKPtcSzyhoPdLYInTWs1coA=";
  dontNpmBuild = true;

  nativeBuildInputs = [pkgs.makeWrapper];
  buildInputs = with pkgs; [nodejs libwebp];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/bin
    cp -r node_modules $out/lib/node_modules
    cp server.js $out/lib/server.js

    # Replace the bundled cwebp with the system one
    rm -f $out/lib/node_modules/cwebp-bin/vendor/cwebp $out/lib/node_modules/.bin/cwebp
    ln -sf ${pkgs.libwebp}/bin/cwebp $out/lib/node_modules/cwebp-bin/vendor/cwebp

    # Replace the bundled gif2webp with the system one
    rm -f $out/lib/node_modules/gif2webp-bin/vendor/gif2webp $out/lib/node_modules/.bin/gif2webp
    ln -sf ${pkgs.libwebp}/bin/gif2webp $out/lib/node_modules/gif2webp-bin/vendor/gif2webp

    makeWrapper ${pkgs.nodejs}/bin/node $out/bin/picgo-server \
      --add-flags "$out/lib/server.js" \
      --set NODE_PATH "$out/lib/node_modules"

    runHook postInstall
  '';

  meta.mainProgram = "picgo-server";
}
