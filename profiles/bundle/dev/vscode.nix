{
  pkgs,
  config,
  ...
}: {
  hm = {
    programs.vscode = {
      enable = true;
      package = pkgs.unstable.vscode;
      mutableExtensionsDir = true;
      profiles.default = {
        userSettings = {
          "telemetry.telemetryLevel" = "off";
          "workbench.startupEditor" = "none";

          "editor.inlayHints.enabled" = "offUnlessPressed";

          "git.confirmSync" = false;
          "git.enableSmartCommit" = true;

          "chat.mcp.gallery.enabled" = true;
          "github.copilot.chat.planAgent.additionalTools" = [
            "context7/*"
            "github/*" # only because it's set in read-only mode

            "brave-search/brave_web_search"
            "brave-search/brave_summarizer"
          ];

          "claudeCode.useTerminal" = true;
        };
        extensions = with pkgs.unstable.vscode-extensions; [
          github.copilot
          github.copilot-chat

          file-icons.file-icons

          usernamehw.errorlens
        ];
      };
    };

    home.file.".vscode/argv.json".text = ''
      {
        "use-inmemory-secretstorage": true,
        "enable-crash-reporter": true
      }
    '';
  };

  environment.systemPackages = with pkgs; [
    nodejs # for mcp
  ];

  sops = {
    secrets = {
      "brave-search-api-key" = {};
      "context7-api-key" = {};
      "github-api-key" = {};
    };
    templates.vscode-user-mcp = {
      owner = config.user.name;
      path = "/home/${config.user.name}/.config/Code/User/mcp.json";
      content = builtins.toJSON {
        servers = {
          context7 = {
            type = "http";
            url = "https://mcp.context7.com/mcp";
            headers.CONTEXT7_API_KEY = "${config.sops.placeholder.context7-api-key}";
          };
          github = {
            command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
            args = ["stdio"];
            env = {
              GITHUB_PERSONAL_ACCESS_TOKEN = "${config.sops.placeholder.github-api-key}";
              GITHUB_READ_ONLY = 1;
            };
          };
          brave-search = {
            command = "${pkgs.lhf.brave-search-mcp-server}/bin/brave-search-mcp-server";
            args = ["--transport" "stdio"];
            env.BRAVE_API_KEY = "${config.sops.placeholder.brave-search-api-key}";
          };
        };
      };
    };
  };

  persist.home.directories = [".config/Code"];
}
