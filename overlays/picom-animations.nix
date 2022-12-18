self: super: {
  picom = super.picom.overrideAttrs (old: {
    src = super.fetchFromGitHub {
      owner = "FT-Labs";
      repo = "picom";
      rev = "ad8feaad127746beaf2afe2b2ea37e7af204a2ac";
      sha256 = "sha256-3lZ41DkNi7FVyEwvMaWwOjLD2aZ6DxZhhvVQMnU6JrI=";
    };
    buildInputs = old.buildInputs ++ [ super.pcre2 ];
  });
}
