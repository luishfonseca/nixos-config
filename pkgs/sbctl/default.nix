{
  pkgs,
  sbctl,
  path,
}: let
  conf = pkgs.writeTextFile {
    name = "sbctl.conf";
    text = ''
      keydir: ${path}/keys
      guid: ${path}/GUID
      files_db: ${path}/files.json
      bundles_db: ${path}/bundles.json
      keys:
        pk:
          privkey: ${path}/keys/PK/PK.key
          pubkey: ${path}/keys/PK/PK.pem
        kek:
          privkey: ${path}/keys/KEK/KEK.key
          pubkey: ${path}/keys/KEK/KEK.pem
        db:
          privkey: ${path}/keys/db/db.key
          pubkey: ${path}/keys/db/db.pem
    '';
  };
in
  pkgs.writeShellScriptBin "sbctl" "${sbctl}/bin/sbctl --config ${conf} $@"
