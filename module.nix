{
  source,
  dreamlib,
}: {
  pkgs,
  config,
  ...
}: let
  inherit (pkgs) stdenv lib;
  inherit (lib) mkOption mkEnableOption types;
  mkColor = default: (mkOption {
    type = types.str;
    description = ''
      An RGB or RGBA color in hexadecimal format without a # symbol.
    '';
    inherit default;
  });
  surfacePalette = types.submodule {
    options = {
      strongest = mkColor "0A0A0A";
      strong = mkColor "141414";
      moderate = mkColor "1C1C1C";
      weak = mkColor "222222";
      weakest = mkColor "282828";
    };
  };
  whitePalette = let
    # white colors all default to pure white
    mkWhite = alpha: mkColor "FFFFFF${alpha}";
  in
    types.submodule {
      options = {
        strongest = mkWhite "FF";
        strong = mkWhite "57";
        moderate = mkWhite "22";
        weak = mkWhite "0E";
        weakest = mkWhite "06";
      };
    };
  blackPalette = let
    # white colors all default to pure white
    mkBlack = alpha: mkColor "000000${alpha}";
  in
    types.submodule {
      options = {
        strongest = mkBlack "FF";
        strong = mkBlack "57";
        moderate = mkBlack "2A";
        weak = mkBlack "0F";
        weakest = mkBlack "06";
      };
    };
  palette = types.submodule {
    options = {
      surface = mkOption {
        type = types.surfacePalette;
        description = ''
          Base colors, usually greys, ordered from darkest (strongest) to
          lightest (weakest). These make up the majority of the theme.
        '';
      };
      white = mkOption {
        type = whitePalette;
        description = ''
          Bright base colors, usually whites, at different levels of
          transparency.
        '';
      };
      black = mkOption {
        type = blackPalette;
        description = ''
          Dark base colors, usually blacks, at different levels of
          transparency.
        '';
      };
      lightColors = mkOption {};
      normalColors = mkOption {};
    };
  };
  cfg = config.gtkNix;
in {
  options.gtkNix = {
    enable = mkEnableOption "Enable the nix-configurable gtk theme";

    palette = mkOption {
      type = palette;
    };

    defaultTransparency = mkOption {
      type = types.int;
      default = 255;
      description = "A number in range 0-255 inclusive.";
    };
  };

  config = let
    inherit (pkgs) stdenv;

    # pass every hexadecimal color through this function, fills out alpha
    # channel if it's missing
    processColor = colorStr: (
      if builtins.stringLength colorStr == 6
      then "${colorStr}${
        let
          trans = lib.trivial.toHexString cfg.defaultTransparency;
        in (
          if builtins.stringLength trans > 2
          then
            (
              abort
              "defaultTransparency set to a value >= 256."
            )
          else if builtins.stringLength trans == 1
          then "0${trans}"
          else trans
        )
      }"
      else if builtins.stringLength colorStr == 8
      then colorStr
      else
        (
          abort
          "color ${colorStr} is not in valid RGB or RGBA hexadecimal format."
        )
    );
    # first patch the original source
    patchedSource = stdenv.mkDerivation {
      name = "patchedPhisch";
      src = source;
      dontBuild = true;
      installPhase = ''
        mkdir $out
        cp -r $src/* $out

        # modify contents of $out, not even using the build directory
      '';
    };

    # "build" the package
    dream = dreamlib.${pkgs.system}.makeOutputs {source = patchedSource;};
    patchedPhisch = dream.packages.phisch;

    # make an installed version of the package
    gtk-nix = stdenv.mkDerivation {
      name = "gtkNixTheme";
      src = patchedPhisch;
      dontBuild = true; # this is just a meta package for installation
      installPhase = ''
        installdir=$out/share/themes/GtkNix
        mkdir -p $installdir
        cp -r $src/lib/node_modules/phisch/gtk-3.0 $installdir
        cp -r $src/lib/node_modules/phisch/assets $installdir
        cp -r $src/lib/node_modules/phisch/index.theme $installdir
      '';
    };
  in {
    gtk.theme = lib.mkIf cfg.enable {
      package = gtk-nix;
      name = "GtkNix";
    };
  };
}
