rec {
  user.altair = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE98aQ0VshDOnylLmZcfEdbuxZllCDtfBYH2786f4nph";

  host.procyon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFKQT5Qg6URIssLGgj+P/F96n6tjeKC2/YvJMsfVhi4";
  user.procyon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJF+oSja/1sRd3MVrwAfF3rFgvqwxL4ENRQ+dQAJUj6o";

  users = builtins.attrValues user;
  hosts = builtins.attrValues host;
}
