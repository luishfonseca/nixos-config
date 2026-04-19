{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  llama-cpp = pkgs.unstable.llama-cpp-vulkan.overrideAttrs (prev: {
    src = inputs.llama-cpp;
    version = "9999";

    patches =
      (prev.patches or [])
      ++ [
        (pkgs.fetchpatch {
          url = "https://github.com/luishfonseca/llama.cpp/commit/eee7d698f4ebc601b00613936fca09a14b1adec1.patch";
          hash = "sha256-7k+BPd5SnGdH1YoMNuvD3YIYcIO2zNydtjlTalXZdIc=";
        })
      ];

    preConfigure = "";
    postPatch = "";
    postInstall = "";
    npmDeps = null;
    nativeBuildInputs =
      builtins.filter
      (x: x.name != "npm-config-hook")
      prev.nativeBuildInputs;

    cmakeFlags =
      prev.cmakeFlags
      ++ [
        # nix shell nixpkgs#resolve-march-native -c resolve-march-native | sed "s/ /;/g"
        (lib.cmakeFeature
          "GGML_ARCH_FLAGS"
          "-march=znver5;-mno-prefetchi;-mno-rdseed;-mshstk;--param=l1-cache-line-size=64;--param=l1-cache-size=48;--param=l2-cache-size=1024")
        (lib.cmakeBool "GGML_LTO" true)
      ];
  });

  modelsDir = "/var/lib/models";
  models = {
    globalSection.version = 1;
    sections = {
      "*" = {
        sleep-idle-seconds = 3600;
        jinja = true;
        mlock = true;
        flash-attn = "on";
        ctk = "q8_0";
        ctv = "q8_0";
      };

      "qwen3.6" = {
        model = "${modelsDir}/unsloth/Qwen3.6-35B-A3B-GGUF/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
        mmproj = "${modelsDir}/unsloth/Qwen3.6-35B-A3B-GGUF/mmproj-F16.gguf";
        ctx-size = 262144;
        temp = 0.6;
        top-p = 0.95;
        top-k = 20;
        min-p = 0.0;
        presence-penalty = 0.0;
        repeat-penalty = 1.0;
        chat-template-kwargs = "{\"enable_thinking\": true}";
      };

      gemma-4 = {
        model = "${modelsDir}/unsloth/gemma-4-26B-A4B-it-GGUF/gemma-4-26B-A4B-it-UD-Q4_K_XL.gguf";
        mmproj = "${modelsDir}/unsloth/gemma-4-26B-A4B-it-GGUF/mmproj-F16.gguf";
        ctx-size = 262144;
        temp = 1.0;
        top-p = 0.95;
        top-k = 64;
        presence-penalty = 1.0;
        repeat-penalty = 1.0;
        chat-template-kwargs = "{\"enable_thinking\": true}";
      };
    };
  };
in {
  services.llama-cpp = {
    enable = true;
    port = 11343;
    model = ./.; # dummy, service is overriden to get models from ini file
    package = llama-cpp;
  };

  systemd.services.llama-cpp = let
    ini = pkgs.formats.iniWithGlobalSection {};
    modelsIni = ini.generate "models.ini" models;
  in {
    environment.XDG_CACHE_HOME = "/var/cache/llama.cpp";
    serviceConfig = {
      ExecStart = let
        cfg = config.services.llama-cpp;
      in [
        ""
        "${cfg.package}/bin/llama-server --host ${cfg.host} --port ${toString cfg.port} --models-preset ${modelsIni}"
      ];
      CacheDirectory = "llama.cpp";
      LimitMEMLOCK = "infinity";
    };
  };

  environment.systemPackages = with pkgs; [
    amdgpu_top
    python3Packages.huggingface-hub
  ];

  lhf.backup.exclude = ["/nix/pst${modelsDir}"];
}
