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

pkgs.buildGoModule rec {
  pname = "kubetail";
  version = "0.14.0";

  src = pkgs.fetchurl {
    url = "https://github.com/kubetail-org/kubetail/releases/download/cli%2Fv${version}/kubetail-${version}-vendored.tar.gz";
    hash = "sha256-EwnwtT3DkXrcTwWkKp6ma0yWFEPwGn0VlTutX2wjnY8=";
  };

  nativeBuildInputs = with pkgs; [
    installShellFiles
  ];

  modRoot = "modules/cli";
  subPackages = [ "." ];

  # Source is already vendored so we can ignore the vendor hash
  vendorHash = null;

  env.GOWORK = "off";

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/kubetail-org/kubetail/modules/cli/cmd.version=${version}"
  ];

  doCheck = false;

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
}
