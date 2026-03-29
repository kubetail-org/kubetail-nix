{
  description = "Kubetail CLI flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/25.11";
    flake-utils.url = "github:numtide/flake-utils";

    # Used for shell.nix
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
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
