rec {
  # user ssh key for each host
  user = {
    altair = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE98aQ0VshDOnylLmZcfEdbuxZllCDtfBYH2786f4nph";
    arcturus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHR+aMbG+4bnDNr7aBZIt9CFvEfNC2yjB68AS0Ix8VwF";
  };

  # host ssh key for each host
  host = {
    arcturus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH4R8ObkUZHV371My9yXuO2ALIMTPYXTLC7kLRMUTF1S";
  };

  users = builtins.attrValues user;
  hosts = builtins.attrValues host;
}
