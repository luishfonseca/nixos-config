{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    unstable.zotero
    lhf.zotero-mcp
  ];

  persist.home.directories = ["Zotero" ".zotero"];
}
