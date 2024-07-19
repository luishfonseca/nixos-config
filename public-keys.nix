rec {
  # user ssh key for each host
  user = {
    altair = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE98aQ0VshDOnylLmZcfEdbuxZllCDtfBYH2786f4nph";
    arcturus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHR+aMbG+4bnDNr7aBZIt9CFvEfNC2yjB68AS0Ix8VwF";
    sirius = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBd4jBcEjIUjhADXAht8UKjCuQHSTLrfjFAnzcfNp9A2";
  };

  # host ssh key for each host
  host = {
    arcturus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH4R8ObkUZHV371My9yXuO2ALIMTPYXTLC7kLRMUTF1S";
    sirius = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKqWoCYdxkedF0J8pNmTXMA9fE5JS1moeK8dScvycbQW";
  };

  users = builtins.attrValues user;
  hosts = builtins.attrValues host;
}
