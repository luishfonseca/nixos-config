{buildGoModule}:
buildGoModule {
  pname = "luks-key-service";
  version = "0.1.0";
  src = ./.;
  vendorHash = null;
  meta.mainProgram = "luks-key-service";
}
