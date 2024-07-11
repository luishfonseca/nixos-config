{profiles, ...}: {
  imports = with profiles; [
    server
  ];

  system.stateVersion = "24.05";
}
