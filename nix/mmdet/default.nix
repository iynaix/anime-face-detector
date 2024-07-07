{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  mmcv,
  pycocotools,
  scipy,
  terminaltables,
  torch,
  torchWithCuda,
  cudaSupport ? false,
}:
let
  torch' = if cudaSupport then torchWithCuda else torch;
  mmcv' = mmcv.override { inherit cudaSupport; };
in
buildPythonPackage rec {
  pname = "mmdet";
  version = "2.28.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "open-mmlab";
    repo = "mmdetection";
    rev = "v${version}";
    hash = "sha256-z24LxnmTmMW+GhCPNxXMbFeiOfJoxGuG6RjKDD8dkDs=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  buildInputs = [ torch' ];

  propagatedBuildInputs = [
    torch'
    mmcv'
    scipy
    pycocotools
    terminaltables
  ];

  pythonImportsCheck = [ "mmdet" ];

  meta = with lib; {
    description = "OpenMMLab Detection Toolbox and Benchmark";
    homepage = "https://github.com/open-mmlab/mmdetection";
    license = licenses.asl20;
    maintainers = with maintainers; [ iynaix ];
  };
}
