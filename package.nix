{
  pkgs,
  source,
  dreamlib,
  cfg,
  ...
}: let
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

  configScss = builtins.toFile "_config.scss" (
    (builtins.concatStringsSep "\n"
      (configSetToSCSS cfg.configuration))
    + "\n${cfg.extraConfigSCSS}"
  );

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
  package = gtk-nix;
  name = "GtkNix";
}
