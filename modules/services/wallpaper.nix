{
  config,
  options,
  lib,
  pkgs,
  ...
}:
# TODO: should blur and darken when building the system
with lib; let
  cfg = config.lhf.services.wallpaper;
in {
  options.lhf.services.wallpaper = {
    enable = mkEnableOption "wallpaper service";
    images = mkOption {
      type = types.listOf types.path;
      default = [];
      description = "List of images to use as wallpaper";
    };
    display = mkOption {
      type = types.enum ["center" "fill" "max" "scale" "tile"];
      default = "fill";
      description = "How to display the wallpaper";
    };
    effects = {
      enable = mkEnableOption "wallpaper effects";
      blur = mkOption {
        type = types.numbers.between 0 128;
        default = 4;
        description = "Blur effect";
      };
      darken = mkOption {
        type = types.numbers.between 0 100;
        default = 40;
        description = "Darken effect";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      hm.systemd.user.services.wallpaper = {
        Unit = {
          Description = "Wallpaper service";
          After = ["graphical-session-pre.target"];
          PartOf = ["graphical-session.target"];
        };
        Install = {
          WantedBy = ["graphical-session.target"];
        };
        Service = let
          images = pkgs.linkFarm "images" (builtins.map
            (p: {
              name = builtins.elemAt (builtins.split "-" (builtins.baseNameOf p)) 2;
              path = p;
            })
            cfg.images);
        in {
          Type = "oneshot";
          ExecStart = let
            setWallpaper = pkgs.writeShellScript "set_wallpaper" ''
              rm ~/.fehbg
              ${pkgs.findutils}/bin/find ${images}/ -type l | ${pkgs.coreutils}/bin/shuf -n 1 | while read wp; do
                echo "Setting wallpaper to $wp"
                ${pkgs.feh}/bin/feh --bg-${cfg.display} $wp

                ${
                if cfg.effects.enable
                then "${pkgs.my.feh-blur}/bin/feh-blur --blur ${toString cfg.effects.blur} --darken ${toString cfg.effects.darken}"
                else ""
              }
              done
            '';
          in "${setWallpaper}";
        };
      };
    }
  ]);
}
