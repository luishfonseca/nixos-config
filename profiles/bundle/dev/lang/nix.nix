{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    alejandra
  ];

  hm.programs.vscode.profiles.default.extensions = with pkgs.unstable.vscode-extensions; [
    jnoortheen.nix-ide
  ];
}
