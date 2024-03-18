{ stdenvNoCC, fetchurl }:
let
  version = "0.0.1";
  baseUrl = "https://github.com/hysts/anime-face-detector/releases/download/v${version}";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "anime-face-models";
  version = "v${version}";

  src = fetchurl {
    url = "${baseUrl}/mmdet_anime-face_yolov3.pth";
    hash = "sha256-OCCLtrikYzGT/rpTLpbtmnlCEpr4/pSLJ7/PjpowoS4=";
  };

  rcnn = fetchurl {
    url = "${baseUrl}/mmdet_anime-face_faster-rcnn.pth";
    hash = "sha256-jNNRTu8aadnkSLh5grx9N8jI9aH8LLuEV504Ll5Ky/E=";
  };

  hrnetv2 = fetchurl {
    url = "${baseUrl}/mmpose_anime-face_hrnetv2.pth";
    hash = "sha256-ZbmVGyn7cIqJwEZ2eAlN0ZsBNs3a8TZuudHm4xDe6EI=";
  };

  dontUnpack = true;
  noConfigure = true;
  noBuild = true;

  installPhase = ''
    mkdir -p $out

    cp $src $out/${finalAttrs.src.name}
    cp $rcnn $out/${finalAttrs.rcnn.name}
    cp $hrnetv2 $out/${finalAttrs.hrnetv2.name}
  '';
})
