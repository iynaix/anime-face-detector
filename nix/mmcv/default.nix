# needed for mmpose < 1.0
# mmpose 1.0+ was a major change that broke imports and loading model data
{
  fetchFromGitHub,
  mmcv,
  torch,
  torchWithCuda,
  torchvision,
  cudaSupport ? false,
}:
let
  torch' = if cudaSupport then torchWithCuda else torch;
  torchvision' = if cudaSupport then torchvision.override { torch = torchWithCuda; } else torchvision;
in
(mmcv.override {
  torch = torch';
  torchvision = torchvision';
}).overridePythonAttrs
  (o: rec {
    version = "1.7.0";
    src = fetchFromGitHub {
      owner = "open-mmlab";
      repo = "mmcv";
      rev = "v${version}";
      hash = "sha256-EVu6D6rTeebTKFCMNIbgQpvBS52TKk3vy2ReReJ9VQE=";
    };

    # logging pollutes stdout
    patches = [ ./remove-logging.patch ];

    propagatedBuildInputs = o.propagatedBuildInputs ++ [ torchvision' ];

    # checks take a long ass time
    doCheck = false;
  })
