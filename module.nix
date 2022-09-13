{
  source,
  dreamlib,
}: {pkgs, ...}: let
  inherit (lib) mkOption mkEnableOption;
  cfg = config.gtkNix;
in {
  options.gtkNix = {
    enable = mkEnableOption "Enable the nix-configurable gtk theme";
  };

  config = let
    inherit (pkgs) stdenv;
    patchedSource = stdenv.mkDerivation {
        name = "gtkNixTheme";
        src = source;
    };
    dream = dreamlib.${pkgs.system}.makeOutputs {inherit patchedSource;};
    gtk-nix = dream.packages.gtk-nix;
  in
    mkIf cfg.enable {
      home.packages = [gtk-nix];
    };
}
