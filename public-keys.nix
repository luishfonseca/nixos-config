rec {
  host.procyon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFKQT5Qg6URIssLGgj+P/F96n6tjeKC2/YvJMsfVhi4";
  user.procyon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJF+oSja/1sRd3MVrwAfF3rFgvqwxL4ENRQ+dQAJUj6o";

  host.pollux = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlyKHxlspL2lzOar+0gVKx61A5v/8pNc38KJfaUNqU9";
  user.pollux = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII4fmK3d9H1G8DtPJXSSYvFRIzhSAKYTh5lO9JCNjI3u";

  host.deneb = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBqBT8URXtsFfABGGp92y1K40VuJXCWK9ivvc8nkRT8T";
  user.deneb = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINF36sbQ+2Vfuup1ErUCZBk3MGk8ieBBztISGff9kE4/";

  users = builtins.attrValues user;
  hosts = builtins.attrValues host;
}
