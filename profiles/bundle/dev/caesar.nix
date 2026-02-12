{pkgs, ...}: {
  environment.variables = with pkgs; {
    LIBCLANG_PATH = "${libclang.lib}/lib";
  };

  hm.programs.vscode.profiles.default = {
    userSettings = {
      "caesar.server.installationOptions" = "source-code";
      "caesar.server.sourcePath" = "/home/luis/pst/projects/secclo/thesis/caesar";
    };
    extensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "caesar";
        publisher = "rwth-moves";
        version = "3.0.0";
        sha256 = "sha256-Kktv8ILPNCPtSHmwNjjJjOr8qdkyKMdsKvfmTS1ABQo=";
      }
    ];
  };
}
