let
  pub = import ../public-keys.nix;

  arcturus = with pub; [host.arcturus user.arcturus];

  deployers = [pub.user.altair];
in {
  "host-keys/arcturus.age".publicKeys = deployers;

  "arcturus/id_ed25519.age".publicKeys = deployers ++ arcturus;
}
