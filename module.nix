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
  defaults = import ./defaults.nix;
  defaultConfiguration = defaults.configuration;
  defaultPalette = defaults.palette;
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
      default = defaults.extraColorSCSS;
      description = "Additional SCSS to add to _colors.scss";
    };

    extraConfigSCSS = mkOption {
      type = types.lines;
      default = defaults.extraConfigSCSS;
      description = "Additional SCSS to add to _config.scss. Pretty useless.";
    };

    defaultTransparency = mkOption {
      type = types.int;
      default = defaults.defaultTransparency;
      description = "A number in range 0-255 inclusive. Applied to all colors \
      that don't already have an alpha channel.";
    };
  };

  config = let
    gtk-nix-theme = pkgs.callPackage ./package.nix {inherit cfg source dreamlib;};
  in {
    gtk.theme = lib.mkIf cfg.enable gtk-nix-theme;
  };
}
