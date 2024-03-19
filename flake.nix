{
  inputs = {
    # mmcv fails to build because of newer torch version
    nixpkgs.url = "github:NixOS/nixpkgs/5a623156afb531ba64c69363776bb2b2fe55e46b";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
    nix2container.url = "github:nlewo/nix2container";
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
          # this sets `pkgs` to a nixpkgs with allowUnfree option set.
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              cudaSupport = true;
            };
          };

          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.
          devShells =
            let
              mkDevenvWithCuda =
                cudaSupport:
                inputs.devenv.lib.mkShell {
                  inherit inputs;
                  pkgs = import nixpkgs {
                    inherit system;
                    config = {
                      allowUnfree = cudaSupport;
                      inherit cudaSupport;
                    };
                  };

                  modules = [
                    {
                      # https://devenv.sh/reference/options/
                      dotenv.disableHint = true;

                      env = {
                        CUDA_SUPPORT = toString cudaSupport;
                        MODEL_PATH = toString (pkgs.callPackage ./nix/anime-face-models { });
                      };

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
                    }
                  ];
                };
            in
            {
              default = mkDevenvWithCuda false;
              cuda = mkDevenvWithCuda true;
            };

          packages = rec {
            default = pkgs.callPackage ./package.nix {
              inherit mmdet mmpose;
              mmcv = mmcv-patched;
              anime-face-models = pkgs.callPackage ./nix/anime-face-models { };
            };
            anime-face-detector = default;
            # gpu support via cuda
            with-cuda = pkgs.callPackage ./package.nix {
              inherit mmdet mmpose;
              mmcv = mmcv-patched;
              anime-face-models = pkgs.callPackage ./nix/anime-face-models { };
              cudaSupport = true;
            };
            anime-face-detector-cuda = with-cuda;
          };
        };
    };
}
