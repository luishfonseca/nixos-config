{
  pkgs,
  sbctl,
}: let
  conf = pkgs.writeTextFile {
    name = "sbctl.conf";
    text = ''
      keydir: /keys/sbctl/keys
      guid: /keys/sbctl/GUID
      files_db: /keys/sbctl/files.json
      bundles_db: /keys/sbctl/bundles.json
      keys:
        pk:
          privkey: /keys/sbctl/keys/PK/PK.key
          pubkey: /keys/sbctl/keys/PK/PK.pem
        kek:
          privkey: /keys/sbctl/keys/KEK/KEK.key
          pubkey: /keys/sbctl/keys/KEK/KEK.pem
        db:
          privkey: /keys/sbctl/keys/db/db.key
          pubkey: /keys/sbctl/keys/db/db.pem
    '';
  };
in
  pkgs.writeShellScriptBin "sbctl" "${sbctl}/bin/sbctl --config ${conf} $@"
