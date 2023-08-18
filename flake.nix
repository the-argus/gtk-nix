{
  description = "A nix flake that provides a home manager module that configures a gtk theme.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    banner = {
      url = "github:the-argus/banner.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    banner,
    flake-utils,
    ...
  }: let
    source = ./src;

    supportedSystems = let
      inherit (flake-utils.lib) system;
    in [
      system.aarch64-linux
      system.x86_64-linux
    ];
  in
    flake-utils.lib.eachSystem supportedSystems (
      system: let
        pkgs = import nixpkgs {inherit system;};

        mkTheme = cfg: let
          override = nixpkgs.lib.attrsets.recursiveUpdate;
        in
          (import ./package.nix {
            inherit source banner pkgs;
            cfg = override (import ./defaults.nix) cfg;
          })
          .package;
      in {
        homeManagerModule = import ./module.nix {
          inherit source banner;
        };

        packages = {
          gtkNix = mkTheme (import ./defaults.nix);
          default = self.packages.${system}.gtkNix;
        };

        inherit mkTheme;
      }
    );
}
