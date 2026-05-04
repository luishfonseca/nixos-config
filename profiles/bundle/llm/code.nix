{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    kimi-cli
  ];

  hm.home.file.".kimi/config.toml".source = (pkgs.formats.toml {}).generate "config.toml" {
    default_model = "kimi-code/kimi-for-coding";
    default_thinking = true;
    telemetry = false;

    models."kimi-code/kimi-for-coding" = {
      provider = "managed:kimi-code";
      model = "kimi-for-coding";
      max_context_size = 262144;
      capabilities = ["image_in" "thinking" "video_in"];
      display_name = "Kimi-k2.6";
    };

    providers."managed:kimi-code" = {
      type = "kimi";
      base_url = "https://api.kimi.com/coding/v1";
      api_key = "";
      oauth = {
        storage = "file";
        key = "oauth/kimi-code";
      };
    };

    services = {
      moonshot_search = {
        base_url = "https://api.kimi.com/coding/v1/search";
        api_key = "";
        oauth = {
          storage = "file";
          key = "oauth/kimi-code";
        };
      };
      moonshot_fetch = {
        base_url = "https://api.kimi.com/coding/v1/fetch";
        api_key = "";
        oauth = {
          storage = "file";
          key = "oauth/kimi-code";
        };
      };
    };
  };

  hm.home.file.".kimi/mcp.json".text = builtins.toJSON {
    mcpServers = {
      chrome-devtools = {
        command = "npx";
        args = ["-y" "chrome-devtools-mcp@latest" "--executablePath" "/run/current-system/sw/bin/chromium" "--headless"];
      };
    };
  };

  persist.home.directories = [".kimi"];
}
