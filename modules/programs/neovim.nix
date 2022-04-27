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
        source = "${config.dotfiles.configDir}/neovim/config.lua";
        onChange = ''
          nvim --headless +PackerInstall +PackerCompile +qa
        '';
      };
      "lazygit/config.yml".source = "${config.dotfiles.configDir}/neovim/lazygit.yml";
    };

    home.file = {
      ".local/bin/nvr" = {
        executable = true;
        text = ''
          #!/bin/sh

          if [ $# -gt 0 ]; then
            exec nvim --server $NVIM_LISTEN_ADDRESS --remote $@
          else
            exec nvim
          fi
        '';
      };
      ".local/bin/lazygit" = {
        executable = true;
        text = ''
          #!/bin/sh
          export PINENTRY_USER_DATA=USE_TTY=1
          export GPG_TTY=$(tty)
          gpg-connect-agent --quiet updatestartuptty /bye > /dev/null
          ${pkgs.lazygit}/bin/lazygit
        '';
      };
    };

    environment.systemPackages = with pkgs; [
      gcc
      python3Packages.pynvim
      ripgrep

      sumneko-lua-language-server
      rnix-lsp
      gopls
      terraform-ls
    ];
  };
}
