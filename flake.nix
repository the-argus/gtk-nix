{
  description = "A nix flake that provides a home manager module that configures a gtk theme.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    source = {
      url = "github:phocus/gtk";
      flake = false;
    };

    dream2nix.url = "github:nix-community/dream2nix";
  };
  outputs = {
    self,
    nixpkgs,
    source,
    dream2nix,
    ...
  } @ inputs: let
    supportedSystems = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    genSystems = nixpkgs.lib.genAttrs supportedSystems;

    dreamlib = genSystems (system:
      dream2nix.lib.init {
        pkgs = import nixpkgs {inherit system;};
        config = {
          projectRoot = ./.;
          overridesDirs = ["${dream2nix}/overrides"];
        };
      });
  in {
    homeManagerModule = import ./module.nix {inherit source dreamlib;};

    # for debugging only
    phocusTheme = let
      dream = dreamlib."x86_64-linux".makeOutputs {inherit source;};
      gtk-nix = dream.packages.gtk-nix;
    in
      gtk-nix;
  };
}
