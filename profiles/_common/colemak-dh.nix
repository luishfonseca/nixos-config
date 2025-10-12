{
  console.useXkbConfig = true;

  services.xserver.xkb = {
    layout = "us";
    model = "pc105";
    variant = "colemak_dh";
  };
}
