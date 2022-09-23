{
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
  palette = {
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
  extraColorSCSS = '''';
  extraConfigSCSS = '''';
  defaultTransparency = 255;
  additionalPatches = [];
}
