{pkgs, ...}: {
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "glmocr" ''
      exec ${pkgs.lhf.glmocr.override {
        inherit (pkgs.unstable) python3Packages;
      }}/bin/glmocr "$@" --config ${./glmocr.yaml}
    '')
  ];
}
