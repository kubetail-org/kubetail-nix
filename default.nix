{
  pkgs ? import <nixpkgs> {},
}: let
  inherit (pkgs) lib;
  sources = builtins.fromJSON (lib.strings.fileContents ./sources.json);

  # mkSourceInstall makes a derivation that installs `kubetail` from source
  mkSourceInstall = {
    version,
    url,
    hash,
    goDepsSrc,
    pnpmDepsSrc,
  }: let
    pname = "kubetail";
    src = pkgs.fetchurl {inherit url hash;};

    # Fetch pnpm dependencies
    pnpmDeps = pkgs.fetchzip {
      nativeBuildInputs = [ pkgs.zstd ];
      url = pnpmDepsSrc.url;
      sha256 = pnpmDepsSrc.hash;
      stripRoot = false;
    };

    # Fetch go dependencies
    goDeps = pkgs.fetchzip {
      nativeBuildInputs = [ pkgs.zstd ];
      url = goDepsSrc.url;
      sha256 = goDepsSrc.hash;
      stripRoot = false;
    };    
  in
    pkgs.stdenv.mkDerivation {
      inherit pname src version pnpmDeps goDeps;

      name = "${pname}-${version}";

      buildInputs = [
        pkgs.go
        pkgs.nodejs
        pkgs.nodePackages.pnpm
        pkgs.pnpm.configHook
      ];

      pnpmRoot = "dashboard-ui";
      pnpmInstallFlags = "--store-dir=${pnpmDeps}/pnpm-store";

      buildPhase = ''
        runHook preBuild

        cd dashboard-ui
        pnpm build
        cd ..
        rm -rf modules/dashboard/website
	      cp -r dashboard-ui/dist modules/dashboard/website

        ln -s ${goDeps}/vendor ./modules/vendor
        cd modules/cli
        GOFLAGS="-mod=vendor" CGO_ENABLED=0 go build \
          -ldflags="-s -w -X 'github.com/kubetail-org/kubetail/modules/cli/cmd.version=${version}'" \
          -o ../../bin/kubetail \
          main.go
        cd ../../

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        install -Dm755 bin/kubetail $out/bin/kubetail

        runHook postInstall
      '';
    };

  # The packages that are tagged releases
  taggedPackages =
    lib.attrsets.mapAttrs
    (k: v: mkSourceInstall {
      version = k;
      url = v.url;
      hash = v.hash;
      goDepsSrc = v.vendorBundles.go;
      pnpmDepsSrc = v.vendorBundles.pnpm;
    })
    (lib.attrsets.filterAttrs
      (k: v: (v.url or null) != null && (v.hash or null) != null)
      sources);

  # This determines the latest /released/ version.
  latest = lib.lists.last (
    builtins.sort
    (x: y: (builtins.compareVersions x y) < 0)
    (builtins.attrNames taggedPackages)
  );
in
  # We want the packages but also add a "default" that just points to the
  # latest released version.
  taggedPackages // {"default" = taggedPackages.${latest};}
