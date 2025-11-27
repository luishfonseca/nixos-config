{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
  ];

  programs = {
    starship = {
      enable = true;
      presets = [
        "no-nerd-font"
      ];
    };

    bash.interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';

    fish.enable = true;
  };

  hm = {
    home.file.".cache/nix-index/files".source =
      inputs.nix-index-database.packages.${pkgs.system}.nix-index-database;

    xdg.stateFile."nix/profiles/profile/manifest.json".text = ''
      {"elements":[],"version":2}
    ''; # hack to make nix-index show flake output

    programs = {
      fish = {
        enable = true;
        interactiveShellInit = ''
          set -U fish_greeting
        '';
      };

      nix-index = {
        enable = true;
        enableFishIntegration = true;
      };

      nix-your-shell = {
        enable = true;
        enableFishIntegration = true;
      };
    };
  };

  persist.home.files = [".local/share/fish/fish_history"];
}
