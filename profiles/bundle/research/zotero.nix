{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    zotero
  ];

  persist.home.directories = ["Zotero"];
}
