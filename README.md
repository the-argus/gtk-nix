# gtk-nix

A flat gtk theme whose colors can be configured with nix. This flake
provides a home manager module which defines ``config.gtk.theme``.
It is recommended to use [banner](https://github.com/the-argus/banner)
color palettes with this gtk theme. A banner yaml file will be read
and applied to the theme.

## Credits

This is a modified version of Phocus Gtk, an excellent gtk theme. This is only
possible thanks to Phocus Gtk's great code structure and use of SCSS.

## Usage

Import this flake. If your configuration is in a flake, add this to
``flake.nix`` (assuming you already use home-manager. if you don't,
go to their README):

```nix
{
  inputs = {
    gtk-nix.url = "github:the-argus/gtk-nix";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { 
    self,
    home-manager,
    gtk-nix
  } @ inputs:
  # my username is the-argus, hopefully you already have this defined
  # in your configuration flake somewhere if you already use home-manager.
  let username = "the-argus"; in
  {
    homeConfigurations.${username} =
      home-manager.lib.homeManagerConfiguration {
        extraSpecialArgs = inputs // {
          inherit gtk-nix;
        };
      };
  };
}
```

This will add ``gtk-nix`` as an available input to any .nix module file
imported to home-manager.

## Example Usage

For more information on what each color option is used for, visit
[the banner palette specifications](https://github.com/the-argus/banner)

### Minimal configuration example

By default, this theme is a nice nord GTK theme.

```nix
{ gtk-nix, ... }:
{
  imports = [ gtk-nix.homeManagerModule ];
  gtkNix.enable = true;
}
```

### Full configuration example

```nix
{ gtk-nix, ... }:
{
  imports = [ gtk-nix.homeManagerModule ];

  gtkNix = {
    enable = true;
    configuration = {
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

    defaultTransparency = 255;
    
    # neither of these options are very useful. They're just so that if
    # I forgot to make something configurable, you can override previous
    # variable definitions.
    extraConfigSCSS = '''';
    extraColorSCSS = '''';
      
    whites = let
      mkWhite = alpha: "f0f0f3${alpha}";
    in {
      strongest = mkWhite "FF";
      strong = mkWhite "DE";
      moderate = mkWhite "57";
      weak = mkWhite "24";
      weakest = mkWhite "0F";
    };
    blacks = let
      mkBlack = alpha: "191724${alpha}";
    in {
      strongest = mkBlack "FF";
      strong = mkBlack "DE";
      moderate = mkBlack "6B";
      weak = mkBlack "26";
      weakest = mkBlack "0F";
    };

    palette = rec {
      # the banner palette format. can also be a path to a yaml file
      # instead of attrs. this example is rose pine.
      base00 = "191724";
      base01 = "1f1d2e";
      base02 = "26233a";
      base03 = "555169";
      base04 = "6e6a86";
      base05 = "e0def4";
      base06 = "f0f0f3";
      base07 = "c5c3ce";
      base08 = "e2e1e7";
      base09 = "eb6f92";
      base0A = "f6c177";
      base0B = "ebbcba";
      base0C = "31748f";
      base0D = "9ccfd8";
      base0E = "c4a7e7";
      base0F = "e5e5e5";

      highlight =   base0E;
      hialt0 =      base0A;
      hialt1 =      base0E;
      hialt2 =      base0B;
      urgent =      base09;
      warn =        base0A;
      confirm =     base0D;
      link =        base0E;

      pfg-highlight =   base00;
      pfg-hialt0 =      base00;
      pfg-hialt1 =      base00;
      pfg-hialt2 =      base05;
      pfg-urgent =      base00;
      pfg-warn =        base00;
      pfg-confirm =     base00;
      pfg-link =        base00;

      ansi00 = base03;
      ansi01 = base09;
      ansi02 = base0D;
      ansi03 = base0A;
      ansi04 = base0C;
      ansi05 = base0E;
      ansi06 = base0B;
      ansi07 = base05;
    };
  };
}
```

## Flake Outputs and Phocus Packaging

### homeManagerModule

Documented above.

### phocusGtk

This flake provides packaging for phocus-gtk, which can also be applied
to the system by just doing ``gtkNix.enable = true;`` and leaving everything
else at default.
Example:

```nix
{ pkgs, gtk-nix, ... }:
{
  environment.systemPackages = [
    (gtk-nix.phocusGtk.${pkgs.system}.package) # and the name of the theme is
    # .name instead of .package
  ];
}
```

## mkTheme

This function provides usage without flakes. Pass the set that normally would
be passed to ``config.gtkNix`` in home-manager to this function to get a set
containing "package" and "name." The only difference is that the ``enable``
option does not need to be set to true.
Example:

```nix
{ pkgs, gtk-nix, ... }:
{
  environment.systemPackages = [
    (gtk-nix.mkTheme.${pkgs.system} {
      palette = {
        # please don't actually use this config... it looks awful
        primaryAccent = "FF0000";
        secondaryAccent = "00FF00";
      };
    }).package
  ];
}
```
