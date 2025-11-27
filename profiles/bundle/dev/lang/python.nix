{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      uv
      pyright
      ruff
    ];
    localBinInPath = true;
  };

  programs.nix-ld.enable = true;

  hm.programs.vscode.profiles.default.extensions = with pkgs.unstable.vscode-extensions; [
    ms-python.python
    ms-python.debugpy
    ms-pyright.pyright
    charliermarsh.ruff
  ];
}
