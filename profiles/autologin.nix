{config, ...}: {
  services.getty.autologinUser = config.user.name;
}
