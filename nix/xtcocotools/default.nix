{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  cython,
  matplotlib,
  numpy,
}:

buildPythonPackage rec {
  pname = "xtcocotools";
  version = "1.14.3";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "jin-s13";
    repo = "xtcocoapi";
    rev = "v${version}";
    hash = "sha256-INEWKn9XCraLxBzNZ6IMm9/gxbAsuZdKHapHvJ/bGfQ=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  propagatedBuildInputs = [
    cython
    matplotlib
    numpy
    setuptools
  ];

  pythonImportsCheck = [ "xtcocotools" ];

  meta = with lib; {
    description = "Extended COCO-API";
    homepage = "https://github.com/jin-s13/xtcocoapi";
    license = licenses.mit;
    maintainers = with maintainers; [ iynaix ];
  };
}
