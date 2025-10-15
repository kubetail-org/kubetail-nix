{
  pkgs ? import (
    let
      lock = builtins.fromJSON (builtins.readFile ./flake.lock);
      nixpkgs = lock.nodes.nixpkgs.locked;
    in
    builtins.fetchTarball {
      url = "https://github.com/${nixpkgs.owner}/${nixpkgs.repo}/archive/${nixpkgs.rev}.tar.gz";
      sha256 = nixpkgs.narHash;
    }
  ) { },
}:

let
  pname = "kubetail";
  version = "0.9.0";

  src = pkgs.fetchFromGitHub {
    owner = "kubetail-org";
    repo = "kubetail";
    tag = "cli/v${version}";
    sha256 = "sha256-n5kHK/cJcDfCy/zQBtHPAxVCnm6RKvHwB5P1o3wthuM=";
  };

  frontend = pkgs.stdenv.mkDerivation {
    inherit version src;
    pname = "${pname}-frontend";

    nativeBuildInputs = [
      pkgs.nodejs
      pkgs.nodePackages.pnpm
      pkgs.pnpm.configHook
    ];

    pnpmRoot = "dashboard-ui";

    pnpmDeps = pkgs.pnpm.fetchDeps {
      inherit pname version;
      src = "${src}/dashboard-ui";
      hash = "sha256-Ph06qKzdle4nFU7PQhrGlxOeP13EqtG43tVd55GkTvg=";
      fetcherVersion = 2;
    };

    buildPhase = ''
      cd dashboard-ui
      pnpm build
      cd ../
    '';

    installPhase = ''
      cp -r dashboard-ui/dist $out
    '';
  };

  backend = pkgs.buildGoModule {
    inherit pname version src;

    nativeBuildInputs = with pkgs; [
      installShellFiles
    ];

    modRoot = "modules/cli";
    subPackages = [ "." ];

    vendorHash = "sha256-lv18257J2txfCWlusSCUQTr/CBxbnwqOSePtGUpRqBE=";

    env.GOWORK = "off";

    ldflags = [
      "-s"
      "-w"
      "-X github.com/kubetail-org/kubetail/modules/cli/cmd.version=${version}"
    ];

    doCheck = false;

    buildPhase = ''
      runHook preBuild

      chmod -R +w vendor/github.com/kubetail-org/kubetail/modules/dashboard
      rm -rf vendor/github.com/kubetail-org/kubetail/modules/dashboard/website
      cp -r ${frontend} vendor/github.com/kubetail-org/kubetail/modules/dashboard/website

      go build -mod="vendor" -ldflags="$ldflags" -o "$GOPATH/bin/" main.go

      runHook postBuild
    '';

    postInstall = ''
      mv $out/bin/{main,${pname}}

      installShellCompletion --cmd ${pname}         \
        --bash <($out/bin/${pname} completion bash) \
        --fish <($out/bin/${pname} completion fish) \
        --zsh  <($out/bin/${pname} completion zsh)
    '';

    meta = {
      description = "Real-time logging dashboard for Kubernetes";
      homepage = "https://github.com/kubetail-org/kubetail";
      mainProgram = pname;
    };
  };
in
backend
