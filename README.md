# gtk-nix
A flat gtk theme whose colors can be configured with nix. This flake
provides a home manager module which defines ``config.gtk.theme``.

# Credits
This is packaging for Phocus Gtk, an excellent gtk theme. The packaging just
patches Phocus to have different properties. This is only possible thanks to
Phocus Gtk's great code structure and use of SCSS.

# Usage
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

# Example Usage
I'm not providing full documentation for every option since I didn't make
phocus gtk and don't know the specifics what options affect. It varies between
different GTK programs.
## Minimal Configuration
An example for a user who just wants a slightly modified version of phocus gtk.
```nix
{ gtk-nix, ... }:
{
  imports = [ gtk-nix.homeManagerModule ];

  gtkNix = {
    enable = true;
    palette = {
      # please don't actually use this config... it looks awful
      primaryAccent = "FF0000";
      secondaryAccent = "00FF00";
    };
  };
}
```
## Maximimalist Configuration
This demonstrates *all* the configuration options available.
It uses the default values for all of them.
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

    palette = {
      whites = let
        mkWhite = alpha: "FFFFFF${alpha}";
      in {
        strongest = mkWhite "FF";
        strong = mkWhite "DE";
        moderate = mkWhite "57";
        weak = mkWhite "24";
        weakest = mkWhite "0F";
      };
      blacks = let
        mkBlack = alpha: "0000000${alpha}";
      in {
        strongest = mkBlack "FF";
        strong = mkBlack "DE";
        moderate = mkBlack "6B";
        weak = mkBlack "26";
        weakest = mkBlack "0F";
      };
      surface = {
        strongest = "0A0A0A";
        strong = "141414";
        moderate = "1C1C1C";
        weak = "222222";
        weakest = "282828";
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
  };
}
```

# Flake Outputs and Phocus Packaging
## homeManagerModule
Documented above.

## phocusGtk
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
    }).package)
  ];
}
```
