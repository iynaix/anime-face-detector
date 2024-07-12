# needed for mmpose < 1.0
# mmpose 1.0+ was a major change that broke imports and loading model data
{
  fetchFromGitHub,
  mmcv,
  torch,
  torchvision,
  runCommandNoCC,
}:
let
  # blank package that isn't used
  noop = runCommandNoCC "noop" { } "mkdir $out";
in
(mmcv.override {
  inherit torch torchvision;
  mmengine = noop;
  pybind11 = noop;
}).overridePythonAttrs
  (o: rec {
    version = "1.7.2";

    src = fetchFromGitHub {
      owner = "open-mmlab";
      repo = "mmcv";
      rev = "v${version}";
      hash = "sha256-WOfvMQh4b4yqfqvOyfLckx9+FbX5WjuiiK0uv8T0zkQ=";
    };

    # logging pollutes stdout
    patches = [ ./remove-logging.patch ];

    propagatedBuildInputs = o.propagatedBuildInputs ++ [ torchvision ];

    # checks take a long ass time
    doCheck = false;
  })
