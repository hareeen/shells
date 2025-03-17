{
  description = "Shells Devshell";

  inputs = {
    # Principle inputs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

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
      }: {
        _module.args.pkgs = import self.inputs.nixpkgs {
          inherit system;
          overlays = [];
          config.allowUnfree = true;
        };
        devShells.default = pkgs.mkShell {
          name = "shell-shell";
          meta.description = "Dev environment for devshells";
          inputsFrom = [config.pre-commit.devShell];
          packages = with pkgs; [
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
        };
      };
    };
}
