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
          # config,
          # self',
          # inputs',
          # pkgs,
          system,
          ...
        }:
        let
          mkPkgsCuda =
            cudaSupport:
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
          mkMmPackagesCuda =
            cudaSupport:
            let
              pkgs' = mkPkgsCuda cudaSupport;
            in
            rec {
              mmcv = pkgs'.python3Packages.callPackage ./nix/mmcv { inherit cudaSupport; };
              mmdet = pkgs'.python3Packages.callPackage ./nix/mmdet { inherit mmcv cudaSupport; };
              mmpose = pkgs'.python3Packages.callPackage ./nix/mmpose {
                inherit mmcv cudaSupport;
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
                cudaSupport:
                inputs.devenv.lib.mkShell rec {
                  inherit inputs;
                  pkgs = mkPkgsCuda cudaSupport;

                  modules = [
                    {
                      # https://devenv.sh/reference/options/
                      dotenv.disableHint = true;

                      env = {
                        CUDA_SUPPORT = toString cudaSupport;
                        MODEL_PATH = toString (pkgs.callPackage ./nix/anime-face-models { });
                      };

                      packages =
                        (pkgs.lib.attrValues (mkMmPackagesCuda cudaSupport))
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
              default = mkDevenvWithCuda false;
              with-cuda = mkDevenvWithCuda true;
            };

          packages =
            let
              mkAnimeFaceDetectorCuda =
                cudaSupport:
                let
                  pkgs' = mkPkgsCuda cudaSupport;
                in
                pkgs'.callPackage ./package.nix (
                  (mkMmPackagesCuda cudaSupport)
                  // {
                    inherit cudaSupport;
                    anime-face-models = pkgs'.callPackage ./nix/anime-face-models { };
                  }
                );
            in
            rec {
              default = mkAnimeFaceDetectorCuda false;
              anime-face-detector = default;
              # gpu support via cuda
              with-cuda = mkAnimeFaceDetectorCuda true;
              anime-face-detector-cuda = with-cuda;
            };
        };
    };
}
