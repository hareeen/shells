{
  description = "Rust Devshell";

  inputs = {
    # Principle inputs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Additional inputs
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    # Devshell
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.flake = false;
  };

  outputs = inputs @ {self, ...}:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      debug = true;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [(inputs.git-hooks + /flake-module.nix)];

      perSystem = {
        config,
        pkgs,
        system,
        lib,
        ...
      }: let
        toolchain = pkgs.fenix.stable;
      in {
        _module.args.pkgs = import self.inputs.nixpkgs {
          inherit system;
          overlays = [inputs.fenix.overlays.default];
          config.allowUnfree = true;
        };
        devShells.default = pkgs.mkShell {
          name = "rust-shell";
          meta.description = "Dev environment for Rust Development";
          inputsFrom = [config.pre-commit.devShell];
          packages = with pkgs; [
            openssl

            (toolchain.withComponents [
              "cargo"
              "clippy"
              "rust-src"
              "rustc"
              "rustfmt"
            ])
            rust-analyzer

            alejandra
          ];

          shellHook = ''
            if [ -z "$IN_NIX_SHELL" ]; then
              export IN_NIX_SHELL=1
              exec ${pkgs.fish}/bin/fish
            fi
          '';
        };
        pre-commit.settings = {
          hooks.alejandra.enable = true;
          hooks.clippy = {
            enable = true;
            settings.allFeatures = true;
            packageOverrides = {
              cargo = toolchain.cargo;
              clippy = toolchain.clippy;
            };
          };
        };
      };
    };
}
