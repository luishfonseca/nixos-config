rec {
  user.altair = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE98aQ0VshDOnylLmZcfEdbuxZllCDtfBYH2786f4nph";

  host.procyon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIARR0zO7ZAXCreck2dNPoy5gnW8I+2CMSX+pfjG/8cLx";
  user.procyon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMgdG/T3Hn99VeeWViwTEE7RlUyLJR/Z0SCyIbrK0+xa";

  users = builtins.attrValues user;
  hosts = builtins.attrValues host;
}
