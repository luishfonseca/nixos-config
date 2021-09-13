# modules/home/neovim/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Neovim configuration.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim

    # TS dependencies
    gcc
    git

    # LSP servers
    rust-analyzer
    nodePackages.pyright
    sumneko-lua-language-server
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Bootstrap Packer
  xdg.dataFile."nvim/site/pack/packer/opt/packer.nvim" = {
    source = "${pkgs.vimPlugins.packer-nvim}/share/vim-plugins/packer.nvim";
    recursive = true;
  };

  xdg.configFile."nvim/init.lua".source = ./init.lua;
  xdg.configFile."nvim/lua".source = ./lua;
}
