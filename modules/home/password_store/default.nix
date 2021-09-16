# modules/home/password_store/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# Password store configuration.

{ ... }:

{
  programs = {
    password-store.enable = true;
    browserpass.enable = true;
    chromium.extensions = [{ id = "naepdomgkenhinolocfifgehidddafch"; }];
  };
}
