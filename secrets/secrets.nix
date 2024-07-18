let
  pub = import ../public-keys.nix;

  altair = with pub; [user.altair];
  arcturus = with pub; [host.arcturus user.arcturus];

  deployers = [pub.user.altair];
in {
  "host-keys/arcturus.age".publicKeys = deployers;

  "arcturus/id_ed25519.age".publicKeys = deployers ++ arcturus;
}
