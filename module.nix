{
  source,
  dreamlib,
}: {
  pkgs,
  config,
  ...
}: let
  inherit (pkgs) stdenv lib;
  inherit (lib) mkOption mkEnableOption;
  cfg = config.gtkNix;
in {
  options.gtkNix = {
    enable = mkEnableOption "Enable the nix-configurable gtk theme";
  };

  config = let
    inherit (pkgs) stdenv;
    # first patch the original source
    patchedSource = stdenv.mkDerivation {
      name = "patchedPhisch";
      src = source;
    };

    # "build" the package
    dream = dreamlib.${pkgs.system}.makeOutputs {inherit patchedSource;};
    patchedPhisch = dream.packages.phisch;

    # make an installed version of the package
    gtk-nix = stdenv.mkDerivation {
      name = "gtkNixTheme";
      src = patchedPhisch;
      dontBuild = true; # this is just a meta package for installation
      installPhase = ''
        installdir=$out/share/themes/GtkNix
        mkdir -p $installdir
        cp $src/lib/node_modules/phisch/gtk-3.0 $installdir
        cp $src/lib/node_modules/phisch/assets $installdir
        cp $src/lib/node_modules/phisch/index.theme $installdir
      '';
    };
  in
    lib.mkIf cfg.enable {
      home.packages = [gtk-nix];
    };
}
