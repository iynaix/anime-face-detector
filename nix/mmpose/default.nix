{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  mmcv,
  torch,
  torchWithCuda,
  json-tricks,
  munkres,
  xtcocotools,
  cudaSupport ? false,
}:
let
  torch' = if cudaSupport then torchWithCuda else torch;
  mmcv' = mmcv.override { inherit cudaSupport; };
in
buildPythonPackage rec {
  pname = "mmpose";
  version = "0.29.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "open-mmlab";
    repo = "mmpose";
    rev = "v${version}";
    hash = "sha256-9x6yW9sqOMQh9cEXraKMbYASRN4ZD80O3M6Z04hiSEQ=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  buildInputs = [ torch' ];

  propagatedBuildInputs = [
    json-tricks
    mmcv'
    munkres
    xtcocotools
  ];

  pythonImportsCheck = [ "mmpose" ];

  meta = with lib; {
    description = "OpenMMLab Pose Estimation Toolbox and Benchmark";
    homepage = "https://github.com/open-mmlab/mmpose";
    license = licenses.asl20;
    maintainers = with maintainers; [ iynaix ];
  };
}
