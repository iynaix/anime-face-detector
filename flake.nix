{
  inputs = {
    # keep nixpkgs pinned to run old versions of mmcv, mmdet, and mmpose
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
    nix2container.url = "github:nlewo/nix2container";
  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devenv.flakeModule ];
      systems = import inputs.systems;

      perSystem =
        { pkgs, system, ... }:
        let
          mkPkgs =
            {
              cudaSupport ? false,
            }:
            import nixpkgs {
              inherit system;
              config = {
                allowUnfreePredicate = nixpkgs.lib.mkIf cudaSupport (
                  pkg:
                  builtins.elem (nixpkgs.lib.getName pkg) [
                    "cuda_cccl"
                    "cuda_cudart"
                    "cuda_cupti"
                    "cuda_nvcc"
                    "cuda_nvml"
                    "cuda_nvml_dev"
                    "cuda_nvrtc"
                    "cuda_nvtx"
                    "cuda_profiler_api"
                    "cudatoolkit-11-cudnn"
                    "libcublas"
                    "libcufft"
                    "libcurand"
                    "libcusolver"
                    "libcusparse"
                    "libnpp"
                  ]
                );
                inherit cudaSupport;
              };
            };
          mkTorchPackages =
            {
              cudaSupport ? false,
            }:
            let
              pkgs' = mkPkgs { inherit cudaSupport; };
              torch = if cudaSupport then pkgs'.python3Packages.torchWithCuda else pkgs'.python3Packages.torch;
              torchvision = pkgs'.python3Packages.torchvision.override { inherit torch; };
            in
            {
              inherit torch torchvision;
            };
          mkMmPackages =
            {
              cudaSupport ? false,
            }:
            let
              pkgs' = mkPkgs { inherit cudaSupport; };
              torchPkgs = mkTorchPackages { inherit cudaSupport; };
            in
            rec {
              mmcv = pkgs'.python3Packages.callPackage ./nix/mmcv torchPkgs;
              mmdet = pkgs'.python3Packages.callPackage ./nix/mmdet {
                inherit mmcv;
                inherit (torchPkgs) torch;
              };
              mmpose = pkgs'.python3Packages.callPackage ./nix/mmpose {
                inherit mmcv;
                inherit (torchPkgs) torch;
                xtcocotools = pkgs'.python3Packages.callPackage ./nix/xtcocotools { };
              };
            };
        in
        {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.
          devShells =
            let
              mkDevenvWithCuda =
                {
                  cudaSupport ? false,
                }:
                inputs.devenv.lib.mkShell {
                  inherit inputs;
                  pkgs = import inputs.nixpkgs-unstable { inherit system; };

                  modules =
                    let
                      pkgs = mkPkgs { inherit cudaSupport; };
                    in
                    [
                      {
                        # https://devenv.sh/reference/options/
                        dotenv.disableHint = true;

                        env = {
                          CUDA_SUPPORT = toString cudaSupport;
                          MODEL_PATH = toString (pkgs.callPackage ./nix/anime-face-models { });
                        } // pkgs.lib.optionalAttrs cudaSupport { CUDA_VISIBLE_DEVICES = "0"; };

                        packages =
                          (pkgs.lib.attrValues (mkMmPackages {
                            inherit cudaSupport;
                          }))
                          ++ (with pkgs.python3Packages; [
                            numpy
                            pillow
                            flake8
                            black
                          ]);

                        # python
                        languages.python.enable = true;
                      }
                    ];
                };
            in
            {
              default = mkDevenvWithCuda { cudaSupport = false; };
              with-cuda = mkDevenvWithCuda { cudaSupport = true; };
            };

          packages =
            let
              mkAnimeFaceDetector =
                {
                  cudaSupport ? false,
                }:
                let
                  pkgs' = mkPkgs { inherit cudaSupport; };
                  torchPkgs = mkTorchPackages { inherit cudaSupport; };
                in
                pkgs'.callPackage ./package.nix (
                  (mkMmPackages { inherit cudaSupport; })
                  // {
                    inherit (torchPkgs) torch;
                    anime-face-models = pkgs'.callPackage ./nix/anime-face-models { };
                  }
                );
            in
            (
              # output mm* packages along with their cuda versions
              (mkMmPackages { })
              // (pkgs.lib.mapAttrs' (name: value: pkgs.lib.nameValuePair "${name}-cuda" value) (mkMmPackages {
                cudaSupport = true;
              }))
              // rec {
                default = mkAnimeFaceDetector { };
                anime-face-detector = default;
                # gpu support via cuda
                with-cuda = mkAnimeFaceDetector { cudaSupport = true; };
                anime-face-detector-cuda = with-cuda;
              }
            );
        };
    };

  nixConfig = {
    extra-substituters = [ "https://anime-face-detector.cachix.org" ];
    extra-trusted-public-keys = [
      "anime-face-detector.cachix.org-1:9Lk0AdIpodsqUfjd8KePju5IDrMEdwZhGHLVAj/Pu5M="
    ];
  };
}
