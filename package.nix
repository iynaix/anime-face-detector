{
  lib,
  python3Packages,
  mmcv,
  mmdet,
  mmpose,
  anime-face-models,
  cudaSupport ? false,
}:
python3Packages.buildPythonApplication {
  pname = "anime-face-detector";
  version = "1.0.0";

  src = ./.;

  postPatch = ''
    substituteInPlace anime_face_detector/__init__.py \
      --replace 'os.environ.get("MODEL_PATH")' '"${anime-face-models}"'
    substituteInPlace cli.py \
      --replace 'os.environ.get("CUDA_SUPPORT")' '"${toString cudaSupport}"'
  '';

  nativeBuildInputs = with python3Packages; [ setuptools ];

  propagatedBuildInputs = [
    mmcv
    mmdet
    mmpose
  ];

  meta = with lib; {
    description = "CLI for hysts/anime-face-detector";
    homepage = "https://github.com/iynaix/anime-face-detector";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ iynaix ];
  };
}
