let
  pub = import ../public-keys.nix;

  arcturus = with pub; [host.arcturus user.arcturus];
  sirius = with pub; [host.sirius user.sirius];

  deployers = [pub.user.altair];
in {
  "host-keys/arcturus.age".publicKeys = deployers;
  "host-keys/sirius.age".publicKeys = deployers;

  "arcturus/id_ed25519.age".publicKeys = deployers ++ arcturus;
  "sirius/id_ed25519.age".publicKeys = deployers ++ sirius;
}
