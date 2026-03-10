{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    unstable.zotero
  ];

  persist.home.directories = ["Zotero" ".zotero"];
}
