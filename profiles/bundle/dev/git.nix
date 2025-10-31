{
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      rerere.enable = true;
      merge.conflictstyle = "zdiff3";
      diff.algorithm = "histogram";
      url."git@github.com:".insteadOf = ["https://github.com/"];
      user = {
        name = "Luís Fonseca";
        email = "luis@lhf.pt";
      };
    };
  };
}
