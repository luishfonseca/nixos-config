{inputs, ...}: {
  imports = [inputs.vscode-server.nixosModules.default];

  services.vscode-server.enable = true;
  systemd.user.services.auto-fix-vscode-server.wantedBy = ["multi-user.target"];

  persist.user.local.directories = [".vscode-server"];
}
