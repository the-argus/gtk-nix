{
  pkgs,
  source,
  dreamlib,
  banner,
  cfg,
  ...
}: let
  inherit (pkgs) stdenv lib;

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

  bannerPalette = banner.lib.util.removeMeta (builtins.mapAttrs (_: value:
      if banner.lib.color.hasOctothorpe value
      then banner.lib.color.removeLeadingOctothorpe value
      else value)
    (
      if builtins.typeOf cfg.palette == "set"
      then cfg.palette
      else if builtins.typeOf cfg.palette == "path"
      then banner.lib.parsers.basicYamlToBanner cfg.palette
      else abort "Palette must be a banner pallete (see github:the-argus/banner.nix/lib/types.nix) or a path to a banner yaml file. Type ${builtins.typeOf cfg.palette} is not supported."
    ));

  whites =
    if cfg.whites == null
    then let
      # white colors all default to nord white
      mkWhite = alpha: "${bannerPalette.base05}${alpha}";
    in {
      strongest = mkWhite "FF";
      strong = mkWhite "DE";
      moderate = mkWhite "57";
      weak = mkWhite "24";
      weakest = mkWhite "0F";
    }
    else cfg.whites;
  blacks =
    if cfg.blacks == null
    then let
      # black colors all default to nord black
      mkBlack = alpha: "${bannerPalette.base00}${alpha}";
    in {
      strongest = mkBlack "FF";
      strong = mkBlack "DE";
      moderate = mkBlack "6B";
      weak = mkBlack "26";
      weakest = mkBlack "0F";
    }
    else cfg.blacks;

  # create _colors.scss and _config.scss
  colorsScss = builtins.toFile "_colors.scss" ''
    ${builtins.concatStringsSep "\n" (colorSetToSCSS "white-" whites)}
    ${builtins.concatStringsSep "\n" (colorSetToSCSS "black-" blacks)}

    ${builtins.concatStringsSep "\n" (colorSetToSCSSSuffix "" bannerPalette)}

    @define-color borders #{"" +$base00};
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
    dontPatch = false;
    patches = cfg.additionalPatches;
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
  patchedDream = dreamlib.${pkgs.system}.makeOutputs {source = patchedSource;};
  dream = dreamlib.${pkgs.system}.makeOutputs {inherit source;};

  patchedPhisch = patchedDream.packages.phisch;
  phisch = dream.package.phisch;

  # make an installed version of the package
  mkGtkNix = src: outname:
    stdenv.mkDerivation {
      name = "gtkNixTheme";
      inherit src;
      dontBuild = true; # this is just a meta package for installation
      installPhase = ''
        installdir=$out/share/themes/${outname}
        mkdir -p $installdir
        cp -r $src/lib/node_modules/phisch/gtk-3.0 $installdir
        cp -r $src/lib/node_modules/phisch/assets $installdir
        cp -r $src/lib/node_modules/phisch/index.theme $installdir
      '';
    };
  themeName = "GtkNix";
in
  pkgs.lib.trivial.warn "gtk-nix has undergone breaking changes. \
If you experience errors, pin commit \
c9ea9874f3de76bcc72a2cf9937565073195923b or update your \
configuration as per the new README." {
    package = mkGtkNix patchedPhisch themeName;
    name = themeName;
  }
