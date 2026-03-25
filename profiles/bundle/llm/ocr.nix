{pkgs, ...}: {
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "glmocr" ''
      exec ${pkgs.lhf.glmocr}/bin/glmocr "$@" --config ${./glmocr.yaml}
    '')
  ];
}
