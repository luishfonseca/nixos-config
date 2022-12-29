final: prev: {
  picom = prev.picom.overrideAttrs (old: {
    src = prev.fetchFromGitHub {
      owner = "FT-Labs";
      repo = "picom";
      rev = "ad8feaad127746beaf2afe2b2ea37e7af204a2ac";
      sha256 = "sha256-3lZ41DkNi7FVyEwvMaWwOjLD2aZ6DxZhhvVQMnU6JrI=";
    };
    buildInputs = old.buildInputs ++ [ prev.pcre2 ];
  });
}
