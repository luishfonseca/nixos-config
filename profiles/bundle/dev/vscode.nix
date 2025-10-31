{pkgs, ...}: {
  hm = {
    programs.vscode = {
      enable = true;
      package = pkgs.unstable.vscode;
      mutableExtensionsDir = true;
      profiles.default.extensions = with pkgs.unstable.vscode-extensions; [
        github.copilot
        github.copilot-chat

        file-icons.file-icons

        usernamehw.errorlens
      ];
    };

    home.file.".vscode/argv.json".text = ''
      {
        "use-inmemory-secretstorage": true,
        "enable-crash-reporter": true,
      }
    '';
  };

  environment.systemPackages = with pkgs; [
    nodejs # for mcp
  ];

  persist.home.directories = [".config/Code"];
}
