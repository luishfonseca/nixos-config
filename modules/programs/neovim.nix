{ config, options, lib, pkgs, inputs, ... }:

with lib;
let cfg = config.lhf.programs.neovim; in
{
  options.lhf.programs.neovim.enable = mkEnableOption "Neovim";

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      package = pkgs.neovim-nightly;
      defaultEditor = true;
      configure.customRC = ''
        let $PINENTRY_USER_DATA="USE_TTY=0"

        lua <<EOF
        dofile(os.getenv("XDG_CONFIG_HOME") .. "/nvim/init.lua")
        EOF
      '';
    };

    home.configFile = {
      "nvim" = {
        source = inputs.lunarVim;
        recursive = true;
        onChange = ''
          nvim --headless +LvimCacheReset +qa
        '';
      };
      "nvim/config.lua" = {
        source = "${config.dotfiles.configDir}/nvim/config.lua";
        onChange = ''
          nvim --headless +PackerInstall +PackerCompile +qa
        '';
      };
    };

    environment.systemPackages = with pkgs; [
      gcc
      python3Packages.pynvim
      ripgrep

      sumneko-lua-language-server
      rnix-lsp
    ];
  };
}
