{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    chromium
  ];

  persist.home.directories = [
    ".config/chromium"
    ".cache/chromium"
    ".pki"
  ];
}
