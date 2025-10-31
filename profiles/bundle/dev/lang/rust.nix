{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    (rust-bin.stable.latest.default.override {
      extensions = ["rust-src" "rust-analyzer"];
    })
    clippy
    gcc
  ];

  hm.programs.vscode.profiles.default.extensions = with pkgs.unstable.vscode-extensions; [
    rust-lang.rust-analyzer
  ];
}
