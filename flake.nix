{
  inputs = {
    # keep nixpkgs pinned to run old versions of mmcv, mmdet, and mmpose
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    systems.url = "github:nix-systems/default";
    nix2container.url = "github:nlewo/nix2container";
  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      perSystem =
        { pkgs, system, ... }:
        let
          mkPkgs =
            {
              cudaSupport ? false,
              rocmSupport ? false,
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
                inherit cudaSupport rocmSupport;
              };
            };
          mkTorchPackages =
            {
              cudaSupport ? false,
              rocmSupport ? false,
            }:
            let
              pkgs' = mkPkgs { inherit cudaSupport rocmSupport; };
              torch =
                if cudaSupport then
                  pkgs'.python3Packages.torchWithCuda
                else if rocmSupport then
                  pkgs'.python3Packages.torchWithRocm
                else
                  pkgs'.python3Packages.torch;
              torchvision = pkgs'.python3Packages.torchvision.override { inherit torch; };
            in
            {
              inherit torch torchvision;
            };
          mkMmPackages =
            {
              cudaSupport ? false,
              rocmSupport ? false,
            }:
            let
              pkgs' = mkPkgs { inherit cudaSupport rocmSupport; };
              torchPkgs = mkTorchPackages { inherit cudaSupport rocmSupport; };
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
              mkShellWithCuda =
                {
                  cudaSupport ? false,
                  rocmSupport ? false,
                }:
                pkgs.mkShell (
                  let
                    pkgs = mkPkgs { inherit cudaSupport rocmSupport; };
                  in
                  {
                    shellHook =
                      ''
                        export CUDA_SUPPORT=${toString cudaSupport}
                        export ROCM_SUPPORT=${toString rocmSupport}
                        export MODEL_PATH=${toString (pkgs.callPackage ./nix/anime-face-models { })}
                      ''
                      + pkgs.lib.optionalString cudaSupport "export CUDA_VISIBLE_DEVICES=0";

                    packages =
                      (pkgs.lib.attrValues (mkMmPackages {
                        inherit cudaSupport rocmSupport;
                      }))
                      ++ (with pkgs.python3Packages; [
                        numpy
                        pillow
                        flake8
                        black
                      ]);
                  }
                );
            in
            {
              default = mkShellWithCuda { cudaSupport = false; };
              with-cuda = mkShellWithCuda { cudaSupport = true; };
              with-rcom = mkShellWithCuda { rocmSupport = true; };
            };

          packages =
            let
              mkAnimeFaceDetector =
                {
                  cudaSupport ? false,
                  rocmSupport ? false,
                }:
                let
                  pkgs' = mkPkgs { inherit cudaSupport rocmSupport; };
                  torchPkgs = mkTorchPackages { inherit cudaSupport rocmSupport; };
                in
                pkgs'.callPackage ./package.nix (
                  (mkMmPackages { inherit cudaSupport rocmSupport; })
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
              // (pkgs.lib.mapAttrs' (name: value: pkgs.lib.nameValuePair "${name}-rocm" value) (mkMmPackages {
                rocmSupport = true;
              }))
              // rec {
                default = mkAnimeFaceDetector { };
                anime-face-detector = default;
                # gpu support via cuda
                with-cuda = mkAnimeFaceDetector { cudaSupport = true; };
                anime-face-detector-cuda = with-cuda;
                # gpu support via rocm
                with-rocm = mkAnimeFaceDetector { rocmSupport = true; };
                anime-face-detector-rocm = with-rocm;
              }
            );
        };
    };
}
