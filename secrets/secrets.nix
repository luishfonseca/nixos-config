let
  pub = import ../public-keys.nix;

  arcturus = with pub; [host.arcturus user.arcturus];
  procyon = with pub; [host.procyon user.procyon];

  deployers = [pub.user.altair];
in {
  "host-keys/arcturus.age".publicKeys = deployers;
  "host-keys/procyon.age".publicKeys = deployers;

  "arcturus/id_ed25519.age".publicKeys = deployers ++ arcturus;
  "procyon/id_ed25519.age".publicKeys = deployers ++ procyon;
}
