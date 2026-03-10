{
  pkgs,
  config,
  ...
}: let
  aichat = pkgs.unstable.aichat.overrideAttrs (prev: {
    postInstall =
      (prev.postInstall or "")
      + ''
        mkdir -p $out/share/aichat/scripts/shell-integration
        cp -r $src/scripts/shell-integration/. $out/share/aichat/scripts/shell-integration/
      '';
  });
in {
  hm.programs = {
    aichat = {
      enable = true;
      package = aichat;
      settings = {
        model = "local:qwen3.5";
        repl_prelude = "session:default";
        clients = [
          {
            type = "openai-compatible";
            name = "local";
            api_base = "http://localhost:${builtins.toString config.services.llama-cpp.port}/v1";
            models = [
              {name = "qwen3-coder-next";}
              {name = "qwen3.5";}
              {
                name = "qwen3.5:thinking";
                real_name = "qwen3.5";
                patch.body = {
                  chat_template_kwargs.enable_thinking = true;
                  temperature = 1.0;
                  top_p = 0.95;
                };
              }
              {
                name = "qwen3.5:code";
                real_name = "qwen3.5";
                patch.body = {
                  chat_template_kwargs.enable_thinking = true;
                  temperature = 0.6;
                  top_p = 0.95;
                };
              }
            ];
          }
        ];
      };
    };

    fish.interactiveShellInit = ''
      source ${aichat}/share/aichat/scripts/shell-integration/integration.fish
    '';
  };
}
