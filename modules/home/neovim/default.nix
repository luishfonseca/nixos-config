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
    rnix-lsp

    # Formatters
    luaformatter
    nixfmt
  ];

  home.sessionVariables = { EDITOR = "nvim"; };

  # Bootstrap Packer
  xdg.dataFile."nvim/site/pack/packer/opt/packer.nvim" = {
    source = "${pkgs.vimPlugins.packer-nvim}/share/vim-plugins/packer.nvim";
    recursive = true;
  };

  xdg.configFile."nvim/init.lua".source = ./init.lua;
  xdg.configFile."nvim/lua".source = ./lua;

  xdg.desktopEntries.nvim = {
    name = "Neovim";
    genericName = "Text Editor";
    exec = "nvim %F";
    terminal = true;
    icon = "nvim";
    categories = [ "Application" "Utility" "TextEditor" ];
    mimeType = [
      "text/english"
      "text/plain"
      "text/x-makefile"
      "text/x-c++hdr"
      "text/x-c++src"
      "text/x-chdr"
      "text/x-csrc"
      "text/x-java"
      "text/x-moc"
      "text/x-pascal"
      "text/x-tcl"
      "text/x-tex"
      "application/x-shellscript"
      "text/x-c"
      "text/x-c++"
      "text/x-lua"
    ];
  };
}
