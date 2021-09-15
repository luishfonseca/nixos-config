# modules/system/ssh/default.nix
#
# Author: Luís Fonseca <luis@lhf.pt>
# URL:    https://github.com/luishfonseca/dotfiles
#
# SSH system configuration.

{ ... }: {
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    permitRootLogin = "no";
  };

  users.users."luis".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHgnSKa8CXwWeqAxnkWBASF2tTJ33VylGWI68DAftIsQ altair" # laptop
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKYZF9DXj0XZ7be9Rc0yC3WKhr30Xbn1kqjbzWBLcC6K sirius" # desktop
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKFlJJH6flIuAxeF68lXgfaXRJkcsGD0IChY5P/0Wajr procyon" # workstation
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBJkc3ohg3yw17YU6Z6GEQW1DBERWa2sohd8fPSupnuM vega" # phone
  ];
}
