{
  pkgs,
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
      hash = "sha256-CwHHR1hhIDWfMJSlFkPuOmf/mTzbNt4RWEHPwJ5fJO8=";
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
    inherit pname version;
    src = "${src}/modules";

    nativeBuildInputs = with pkgs; [
      installShellFiles
    ];

    modRoot = "cli";
    subPackages = [ "." ];

    prePatch = ''
      rm -rf dashboard/website
      cp -r ${frontend} dashboard/website
    '';

    vendorHash = "sha256-0ThV7Q7FJeJEti6ic6MCai+OjSQairV5IUv1gZ5SpPY=";

    ldflags = [
      "-s"
      "-w"
      "-X github.com/kubetail-org/kubetail/modules/cli/cmd.version=${version}"
    ];

    doCheck = false;

    preBuild = ''
      export GOWORK="off"
    '';

    postInstall = ''
      mv $out/bin/{cli,${pname}}

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
