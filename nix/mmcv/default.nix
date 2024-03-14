{
  fetchFromGitHub,
  mmcv,
  torchvision,
}:
# needed for mmpose < 1.0
# mmpose 1.0+ was a major change that broke imports and loading model data
mmcv.overridePythonAttrs (o: rec {
  version = "1.7.0";
  src = fetchFromGitHub {
    owner = "open-mmlab";
    repo = "mmcv";
    rev = "v${version}";
    hash = "sha256-EVu6D6rTeebTKFCMNIbgQpvBS52TKk3vy2ReReJ9VQE=";
  };

  # logging pollutes stdout
  patches = [ ./remove-logging.patch ];

  propagatedBuildInputs = o.propagatedBuildInputs ++ [ torchvision ];

  # checks take a long ass time
  doCheck = false;
})
