{
  inputs = {
    # mmcv fails to build because of newer torch version
    nixpkgs.url = "github:NixOS/nixpkgs/5a623156afb531ba64c69363776bb2b2fe55e46b";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
  };
  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devenv.flakeModule ];
      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        let
          ps = pkgs.python3Packages;
          # python dependencies locked to the specific nixpkgs
          mmcv-patched = ps.callPackage ./nix/mmcv { };
          mmdet = (ps.callPackage ./nix/mmdet { mmcv = mmcv-patched; });
          mmpose = (
            ps.callPackage ./nix/mmpose {
              mmcv = mmcv-patched;
              xtcocotools = ps.callPackage ./nix/xtcocotools { };
            }
          );
        in
        {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.
          devenv.shells.default = {
            # https://devenv.sh/reference/options/
            dotenv.disableHint = true;

            # python
            languages.python = {
              enable = true;
              # provide hard to compile packages to pip
              package = pkgs.python3.withPackages (
                ps: with ps; [
                  mmcv-patched
                  mmdet
                  mmpose
                  numpy
                  pillow
                  flake8
                  black
                ]
              );
            };
          };

          packages = rec {
            default = pkgs.callPackage ./package.nix {
              mmcv = mmcv-patched;
              inherit mmdet mmpose;
            };
            anime-face-detector = default;
          };
        };
    };
}
