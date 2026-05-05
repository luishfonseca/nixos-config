{pkgs, ...}: {
  console.keyMap = pkgs.runCommand "xkb-console-keymap" { preferLocalBuild = true; } ''
    '${pkgs.buildPackages.ckbcomp}/bin/ckbcomp' \
      -model 'pc105' -layout 'us' \
      -variant 'colemak_dh' > "$out"
  '';
}
