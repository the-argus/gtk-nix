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
  defaultPalette = {
    surface = {
      strongest = "0A0A0A";
      strong = "141414";
      moderate = "1C1C1C";
      weak = "222222";
      weakest = "282828";
    };
    whites = let
      # white colors all default to pure white
      mkWhite = alpha: mkColor "FFFFFF${alpha}";
    in {
      strongest = mkWhite "FF";
      strong = mkWhite "57";
      moderate = mkWhite "22";
      weak = mkWhite "0E";
      weakest = mkWhite "06";
    };
    blacks = let
      # white colors all default to pure white
      mkBlack = alpha: mkColor "000000${alpha}";
    in {
      strongest = mkBlack "FF";
      strong = mkBlack "57";
      moderate = mkBlack "2A";
      weak = mkBlack "0F";
      weakest = mkBlack "06";
    };
    normalColors = {
      red = "DA5858";
      orange = "ED9454";
      yellow = "E8CA5E";
      green = "3FC661";
      cyan = "5CD8E6";
      blue = "497EE9";
      purple = "7154F2";
      pink = "D56CC3";
    };
    lightColors = {
      red = "E36D6D";
      orange = "FCA669";
      yellow = "FADD75";
      green = "61D67E";
      cyan = "7EEAF6";
      blue = "5D8DEE";
      purple = "8066F5";
      pink = "DF81CF";
    };
    primaryAccent = "7154F2";
    secondaryAccent = "3FC661";
  };
  mkColor = default: (mkOption {
    type = types.str;
    description = ''
      An RGB or RGBA color in hexadecimal format without a # symbol.
    '';
    inherit default;
  });

  surfacePalette = types.submodule {
    options =
      builtins.mapAttrs (name: value: mkColor value)
      defaultPalette.surface;
  };
  whitePalette = types.submodule {
    options =
      builtins.mapAttrs (name: value: mkColor value)
      defaultPalette.whites;
  };
  blackPalette = types.submodule {
    options =
      builtins.mapAttrs (name: value: mkColor value)
      defaultPalette.blacks;
  };
  mkColorPalette = colors:
    mkOption {
      type = types.submodule {
        options = builtins.mapAttrs (name: color: mkColor color) colors;
      };
      description = "Highlight colors used rarely. Only colors you \
      select as accents are used in every application.";
      default = colors;
    };
  palette = types.submodule {
    options = {
      surface = mkOption {
        type = surfacePalette;
        description = ''
          Base colors, usually greys, ordered from darkest (strongest) to
          lightest (weakest). These make up the majority of the theme.
        '';
        default = defaultPalette.surface;
      };
      whites = mkOption {
        type = whitePalette;
        description = ''
          Bright base colors, usually whites, at different levels of
          transparency.
        '';
        default = defaultPalette.whites;
      };
      blacks = mkOption {
        type = blackPalette;
        description = ''
          Dark base colors, usually blacks, at different levels of
          transparency.
        '';
        default = defaultPalette.blacks;
      };
      normalColors = mkColorPalette defaultPalette.normalColors;
      lightColors = mkColorPalette defaultPalette.lightColors;
      primaryAccent = mkColor defaultPalette.primaryAccent;
      secondaryAccent = mkColor defaultPalette.secondaryAccent;
    };
  };
  cfg = config.gtkNix;
in {
  options.gtkNix = {
    enable = mkEnableOption "Enable the nix-configurable gtk theme";

    palette = mkOption {
      type = palette;
      default = defaultPalette;
    };

    configuration = mkOption {
      type = types.submodule {
        options = {
          spacing-small = mkOption {
            type = types.str;
            default = "0.3em";
            description = "CSS spacing value for smaller gaps.";
          };
          spacing-medium = mkOption {
            type = types.str;
            default = "0.6em";
            description = "CSS spacing value for medium gaps.";
          };
          spacing-large = mkOption {
            type = types.str;
            default = "0.9em";
            description = "CSS spacing value for large gaps.";
          };
          tint-weak = mkOption {
            type = types.float;
            default = 0.3;
            description = "Value between 0 and 1 representing the opacity of \
            *very* transparent elements.";
          };
          tint-medium = mkOption {
            type = types.float;
            default = 0.6;
            description = "Value between 0 and 1 representing the opacity of \
            somewhat transparent elements.";
          };
          tint-strong = mkOption {
            type = types.float;
            default = 0.8;
            description = "Value between 0 and 1 representing the opacity of \
            *slightly* transparent elements.";
          };
          border-size = mkOption {
            type = types.str;
            default = "0.2em";
            description = "CSS spacing value for the thickness of borders.";
          };
          radius = mkOption {
            type = types.str;
            default = "0.5em";
            description = "CSS spacing value for how round corners should be.";
          };
          disabled-opacity = mkOption {
            type = types.float;
            default = 0.3;
            description = "Opacity value from 0 to 1 for disabled UI elements.";
          };
        };
      };
    };

    extraColorSCSS = mkOption {
      type = types.lines;
      default = '''';
      description = "Additional SCSS to add to _colors.scss";
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

    # function that converts an RGBA hex string to a list of R G B A, 0-255
    hexToRGBA = hex: let
      inherit (lib.lists) sublist range reverseList;
      inherit (lib.strings) stringToCharacters toUpper toInt;
      getChannel = channelNum: sublist (channelNum * 2) 2 (stringToCharacters (processColor (toUpper hex)));
      channels = map getChannel (range 0 3); # RGBA channels 1-4 in a list, still hex

      twoDigitHexToDecimal = twoDigitHex: let
        hexmap = {
          "A" = 10;
          "B" = 11;
          "C" = 12;
          "D" = 13;
          "E" = 14;
          "F" = 15;
        };
        oneDigitHexToDecimal = oneDigitHex:
          if builtins.hasAttr oneDigitHex hexmap
          then hexmap.${oneDigitHex}
          else toInt oneDigitHex;
        decimalDigits = reverseList (map oneDigitHexToDecimal twoDigitHex);
        # scale each digit to its place (first place is * 1, second
        # place is * 16)
        decimalValues = lib.lists.imap0 (index: value:
          if index == 0
          then value
          else if index == 1
          then (index * 16) * value
          else abort "twoDigitHexToDecimal can only process a hex string \
          with length 2.")
        decimalDigits;
      in
        # add all the decimal values of each hex digit
        lib.lists.foldr (a: b: a + b) 0 decimalValues;
    in
      map twoDigitHexToDecimal channels;

    colorSetToSCSS = prefix: set:
      lib.attrsets.mapAttrsToList (name: value: "\$${prefix}${name}: \
      rgba(${builtins.concatStringsSep ", " (hexToRGBA value)});") set;

    colorSetToSCSSSuffix = suffix: set:
      lib.attrsets.mapAttrsToList (name: value: "\$${name}${suffix}: \
      rgba(${builtins.concatStringsSep ", " (hexToRGBA value)});") set;

    # create _colors.scss and _config.scss
    colorsScss = builtins.toFile "_colors.scss" ''
      ${builtins.concatStringsSep "\n" (colorSetToSCSS "surface-" cfg.palette.surface)}
      ${builtins.concatStringsSep "\n" (colorSetToSCSS "white-" cfg.palette.whites)}
      ${builtins.concatStringsSep "\n" (colorSetToSCSS "black-" cfg.palette.blacks)}

      ${builtins.concatStringsSep "\n" (colorSetToSCSSSuffix "-normal" cfg.palette.normalColors)}
      ${builtins.concatStringsSep "\n" (colorSetToSCSSSuffix "-light" cfg.palette.lightColors)}

      $accent-primary: rgba(${builtins.concatStringsSep ", " (hexToRGBA cfg.primaryAccent)});
      $accent-secondary: rgba(${builtins.concatStringsSep ", " (hexToRGBA cfg.secondaryAccent)});

      @define-color borders #{"" +$surface-strong};
      ${cfg.extraColorSCSS}
    '';

    # first patch the original source
    patchedSource = stdenv.mkDerivation {
      name = "patchedPhisch";
      src = source;
      dontBuild = true;
      installPhase = ''
        mkdir -p $out/scss/gtk-3.0
        cp -r $src/* $out

        # modify contents of $out, not even using the build directory
        cp ${colorsScss} $out/scss/gtk-3.0/_colors.scss
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
