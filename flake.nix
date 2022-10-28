{
  description = "A nix flake that provides a home manager module that configures a gtk theme.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    dream2nix = {
      url = "github:nix-community/dream2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    nixpkgs,
    dream2nix,
    ...
  }: let
    source = ./src;

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

    phocusGtk =
      genSystems
      (system: let
        pkgs = import nixpkgs {localSystem = {inherit system;};};
      in (import ./package.nix {
        inherit source dreamlib pkgs;
        cfg = import ./defaults.nix;
        dontPatch = true;
      }));

    mkTheme = cfg: (genSystems
      (
        system: let
          override = pkgs.lib.attrsets.recursiveUpdate;
          pkgs = import nixpkgs {localSystem = {inherit system;};};
        in
          import ./package.nix {
            inherit source dreamlib pkgs;
            cfg = override (import ./defaults.nix) cfg;
          }
      ));
  };
}
