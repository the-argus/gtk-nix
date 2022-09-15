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
  defaultConfiguration = {
    spacing-small = "0.3em";
    spacing-medium = "0.6em";
    spacing-large = "0.9em";
    tint-weak = 0.3;
    tint-medium = 0.6;
    tint-strong = 0.9;
    border-size = "0.2em";
    radius = "0.5em";
    disabled-opacity = 0.3;
  };
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
      mkWhite = alpha: "FFFFFF${alpha}";
    in {
      strongest = mkWhite "FF";
      strong = mkWhite "DE";
      moderate = mkWhite "57";
      weak = mkWhite "24";
      weakest = mkWhite "0F";
    };
    blacks = let
      # white colors all default to pure white
      mkBlack = alpha: "000000${alpha}";
    in {
      strongest = mkBlack "FF";
      strong = mkBlack "DE";
      moderate = mkBlack "6B";
      weak = mkBlack "26";
      weakest = mkBlack "0F";
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
      default = defaultConfiguration;
      type = types.submodule {
        options = {
          spacing-small = mkOption {
            type = types.str;
            default = defaultConfiguration.spacing-small;
            description = "CSS spacing value for smaller gaps.";
          };
          spacing-medium = mkOption {
            type = types.str;
            default = defaultConfiguration.spacing-medium;
            description = "CSS spacing value for medium gaps.";
          };
          spacing-large = mkOption {
            type = types.str;
            default = defaultConfiguration.spacing-large;
            description = "CSS spacing value for large gaps.";
          };
          tint-weak = mkOption {
            type = types.float;
            default = defaultConfiguration.tint-weak;
            description = "Value between 0 and 1 representing the opacity of \
            *very* transparent elements.";
          };
          tint-medium = mkOption {
            type = types.float;
            default = defaultConfiguration.tint-medium;
            description = "Value between 0 and 1 representing the opacity of \
            somewhat transparent elements.";
          };
          tint-strong = mkOption {
            type = types.float;
            default = defaultConfiguration.tint-strong;
            description = "Value between 0 and 1 representing the opacity of \
            *slightly* transparent elements.";
          };
          border-size = mkOption {
            type = types.str;
            default = defaultConfiguration.border-size;
            description = "CSS spacing value for the thickness of borders.";
          };
          radius = mkOption {
            type = types.str;
            default = defaultConfiguration.radius;
            description = "CSS spacing value for how round corners should be.";
          };
          disabled-opacity = mkOption {
            type = types.float;
            default = defaultConfiguration.disabled-opacity;
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

      # convert to decimal
      decimalChannels = map twoDigitHexToDecimal channels;
    in
      # divide the last element by 255 so its a float in 1
      map builtins.toString ((sublist 0 3 decimalChannels)
        ++ (map (item: (item / 255.0)) (sublist 3 1 decimalChannels)));

    colorSetToSCSS = prefix: set:
      lib.attrsets.mapAttrsToList (
        name: value: "\$${prefix}${name}: rgba(${builtins.concatStringsSep ", " (hexToRGBA value)});"
      )
      set;

    colorSetToSCSSSuffix = suffix: set:
      lib.attrsets.mapAttrsToList (
        name: value: "\$${name}${suffix}: rgba(${builtins.concatStringsSep ", " (hexToRGBA value)});"
      )
      set;

    configSetToSCSS = conf: let
      toS = cfgVal: let
        type = builtins.typeOf cfgVal;
      in
        if type == "float"
        then builtins.toString cfgVal
        else if type == "string"
        then cfgVal
        else abort "I only set up configuration values to be either \
        floats or strings... open an issue if I forgot to expand this.\
        But otherwise you should never get this error.";
    in
      lib.attrsets.mapAttrsToList
      (name: value: "\$${name}: ${toS value};")
      conf;

    # create _colors.scss and _config.scss
    colorsScss = builtins.toFile "_colors.scss" ''
      ${builtins.concatStringsSep "\n" (colorSetToSCSS "surface-" cfg.palette.surface)}
      ${builtins.concatStringsSep "\n" (colorSetToSCSS "white-" cfg.palette.whites)}
      ${builtins.concatStringsSep "\n" (colorSetToSCSS "black-" cfg.palette.blacks)}

      ${builtins.concatStringsSep "\n" (colorSetToSCSSSuffix "-normal" cfg.palette.normalColors)}
      ${builtins.concatStringsSep "\n" (colorSetToSCSSSuffix "-light" cfg.palette.lightColors)}

      $accent-primary: rgba(${builtins.concatStringsSep ", " (hexToRGBA cfg.palette.primaryAccent)});
      $accent-secondary: rgba(${builtins.concatStringsSep ", " (hexToRGBA cfg.palette.secondaryAccent)});

      @define-color borders #{"" +$surface-strong};
      ${cfg.extraColorSCSS}
    '';

    configScss =
      builtins.toFile "_config.scss" (builtins.concatStringsSep "\n"
        (configSetToSCSS cfg.configuration));

    # first patch the original source
    patchedSource = stdenv.mkDerivation {
      name = "patchedPhisch";
      src = source;
      dontBuild = true;
      installPhase = ''
        mkdir -p $out/scss/gtk-3.0
        cp -r $src/* $out

        ${pkgs.coreutils-full}/bin/chmod -R +w $out

        # modify contents of $out, not even using the build directory
        cp ${colorsScss} $out/scss/gtk-3.0/_colors.scss
        cp ${configScss} $out/scss/gtk-3.0/_config.scss
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
