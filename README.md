# Nix Packaging for Kubetail

This repository contains Nix packaging for the [Kubetail](https://github.com/kubetail-org/kubetail) project. It is meant to be consumed primarily as a flake but the `default.nix` can also be imported directly by non-flakes too.

Available Packages:

- `kubetail` (default) - The kubetail CLI tool

Additional packages may be added in the future.

## Flake

```console
# Try without installing
nix run github:kubetail-org/kubetail-nix

# Open a shell with `kubetail` installed
nix shell github:kubetail-org/kubetail-nix

# Install to your profile
nix profile add github:kubetail-org/kubetail-nix
```

## Non-Flake

```console
# Try without installing
nix-build https://github.com/kubetail-org/kubetail-nix

# Open a shell with `kubetail` installed
nix-shell https://github.com/kubetail-org/kubetail-nix

# Install to your profile
nix-env -i -f https://github.com/kubetail-org/kubetail-nix
```

## Usage

After installation, run:

```console
kubetail --help
```

For more information on using Kubetail, visit the [source repo](https://github.com/kubetail-org/kubetail) or the [official documentation](https://www.kubetail.com/).

## Development

### Flake

Start the `kubetail-nix-dev` container:

```console
docker compose up
```

Start a shell inside the container:

```console
docker exec -it kubetail-nix-dev bash
```

This project will be mounted in the `/kubetail-nix` directory where you can run `nix build .`, etc.

### Non-Flake

Start a shell inside a nix container:

```console
docker run --rm -it -v "$PWD":/kubetail-nix nixos/nix bash
```

This project will be mounted in the `/kubetail-nix` directory where you can run `nix-build .`, etc.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues related to:
- This Nix packaging: Open an issue in this repository
- The kubetail tool itself: Visit the [kubetail repository](https://github.com/kubetail-org/kubetail)
