{
  source,
  dreamlib,
  banner,
}: {
  pkgs,
  config,
  ...
}: let
  inherit (pkgs) lib;
  inherit (lib) mkOption mkEnableOption types;
  defaults = import ./defaults.nix;

  nullColor = mkOption {
    type = types.nullOr types.str;
    description = ''
      An RGB or RGBA color in hexadecimal format without a # symbol.
    '';
    default = null;
  };

  whitePalette = types.submodule {
    options =
      builtins.mapAttrs (_: _: nullColor)
      defaults.whites;
  };
  blackPalette = types.submodule {
    options =
      builtins.mapAttrs (_: _: nullColor)
      defaults.blacks;
  };
  cfg = config.gtkNix;
in {
  options.gtkNix = {
    enable = mkEnableOption "Enable the nix-configurable gtk theme";

    palette = mkOption {
      type = types.oneOf [
        banner.lib.types.banner
        types.path
      ];
      default = defaults.palette;
    };

    # you can optionally define exactly
    # what you want the blacks and whites
    # of the color palette to be.
    # by default, they are base00 and
    # base05
    blacks = mkOption {
      type = types.nullOr blackPalette;
      default = null;
    };
    whites = mkOption {
      type = types.nullOr whitePalette;
      default = null;
    };

    configuration = mkOption {
      default = defaults.configuration;
      type = types.submodule {
        options = {
          spacing-small = mkOption {
            type = types.str;
            default = defaults.configuration.spacing-small;
            description = "CSS spacing value for smaller gaps.";
          };
          spacing-medium = mkOption {
            type = types.str;
            default = defaults.configuration.spacing-medium;
            description = "CSS spacing value for medium gaps.";
          };
          spacing-large = mkOption {
            type = types.str;
            default = defaults.configuration.spacing-large;
            description = "CSS spacing value for large gaps.";
          };
          tint-weak = mkOption {
            type = types.float;
            default = defaults.configuration.tint-weak;
            description = "Value between 0 and 1 representing the opacity of \
            *very* transparent elements.";
          };
          tint-medium = mkOption {
            type = types.float;
            default = defaults.configuration.tint-medium;
            description = "Value between 0 and 1 representing the opacity of \
            somewhat transparent elements.";
          };
          tint-strong = mkOption {
            type = types.float;
            default = defaults.configuration.tint-strong;
            description = "Value between 0 and 1 representing the opacity of \
            *slightly* transparent elements.";
          };
          border-size = mkOption {
            type = types.str;
            default = defaults.configuration.border-size;
            description = "CSS spacing value for the thickness of borders.";
          };
          radius = mkOption {
            type = types.str;
            default = defaults.configuration.radius;
            description = "CSS spacing value for how round corners should be.";
          };
          disabled-opacity = mkOption {
            type = types.float;
            default = defaults.configuration.disabled-opacity;
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

    additionalPatches = mkOption {
      type = types.listOf types.path;
      default = [];
      description = "A list of patches to apply to the Phocus GTK source code.";
    };
  };

  config = let
    gtk-nix-theme = import ./package.nix {
      inherit
        pkgs
        cfg
        source
        dreamlib
        banner
        ;
    };
  in {
    gtk.theme = lib.mkIf cfg.enable gtk-nix-theme;
  };
}
