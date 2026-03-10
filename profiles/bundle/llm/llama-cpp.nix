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

      qwen3-coder-next = {
        model = "${modelsDir}/unsloth/Qwen3-Coder-Next-GGUF/Qwen3-Coder-Next-UD-Q4_K_XL.gguf";
        ctx-size = 262144;
        temp = 1.0;
        top-p = 0.95;
        min-p = 0.01;
        top-k = 40;
      };

      "qwen3.5" = {
        model = "${modelsDir}/unsloth/Qwen3.5-35B-A3B-GGUF/Qwen3.5-35B-A3B-UD-Q4_K_XL.gguf";
        mmproj = "${modelsDir}/unsloth/Qwen3.5-35B-A3B-GGUF/mmproj-F16.gguf";
        ctx-size = 262144;
        temp = 0.7;
        top-p = 0.8;
        top-k = 20;
        min-p = 0.0;
        presence-penalty = 1.5;
        repeat-penalty = 1.0;
        chat-template-kwargs = "{\"enable_thinking\": false}";
      };

      glm-ocr = {
        model = "${modelsDir}/ggml-org/GLM-OCR-GGUF/GLM-OCR-Q8_0.gguf";
        mmproj = "${modelsDir}/ggml-org/GLM-OCR-GGUF/mmproj-GLM-OCR-Q8_0.gguf";
        ctx-size = 131072;
        temp = 0.0;
        top-k = 1.0;
        top-p = 1.0;
        min-p = 0.0;
      };

      bge-m3 = rec {
        model = "${modelsDir}/gpustack/bge-m3-GGUF/bge-m3-Q8_0.gguf";
        ctx-size = 8192;
        b = ctx-size;
        ub = ctx-size;
        embedding = true;
        pooling = "cls";
      };

      bge-reranker-v2-m3 = rec {
        model = "${modelsDir}/gpustack/bge-reranker-v2-m3-GGUF/bge-reranker-v2-m3-Q8_0.gguf";
        ctx-size = 8192;
        b = ctx-size;
        ub = ctx-size;
        reranking = true;
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
}
