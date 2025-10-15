{
  description = "Kubetail CLI flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        myPackage = pkgs.callPackage ./default.nix { };
      in
      {
        packages.default = myPackage;

        # For nix run
        apps.default = {
          type = "app";
          program = "${myPackage}/bin/kubetail";
          meta = myPackage.meta;
        };
      }
    );
}
