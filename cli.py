import argparse
import cv2
import json
import warnings
from typing import TypedDict

# disable warnings for mmdet
warnings.filterwarnings("ignore", category=UserWarning)


import anime_face_detector  # noqa: E402


GPU_SUPPORT = False


class Face(TypedDict):
    xmin: int
    ymin: int
    xmax: int
    ymax: int


def detect_faces(
    detector, img: str, *, face_score_threshold: float, device: str
) -> list[Face]:
    # create the detector
    detector = anime_face_detector.create_detector(
        # faster-rcnn is also available
        face_detector_name=detector,
        # "cuda:0" is also available, but takes forever to build
        device="cuda:0" if device == "gpu" else "cpu",
    )

    faces = []
    for pred in detector(img):
        face = pred["bbox"]
        score = face[4]
        if score < face_score_threshold:
            continue

        # produces negative values sometimes?
        faces.append(
            {
                "xmin": max(0, int(face[0])),
                "ymin": max(0, int(face[1])),
                "xmax": max(0, int(face[2])),
                "ymax": max(0, int(face[3])),
            }
        )
    return faces


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--detector",
        type=str,
        default="best",
        choices=["best", "yolov3", "faster-rcnn"],
        help="choose the detector to use (default: %(default)s)",
    )
    parser.add_argument(
        "--face-score-threshold",
        type=float,
        default=0.5,
        help="set the face score threshold (default: %(default)s)",
    )
    parser.add_argument(
        "images",
        nargs="+",
        metavar="IMAGES",
        help="List of images to process",
    )
    if GPU_SUPPORT:
        parser.add_argument("--device", type=str, default="gpu", choices=["gpu", "cpu"])
    args = parser.parse_args()

    faces = []
    detector_kwargs = {
        "face_score_threshold": args.face_score_threshold,
        "device": args.device if GPU_SUPPORT else "cpu",
    }
    for img in args.images:
        if args.detector == "best":
            yolov3_faces = detect_faces(
                "yolov3",
                img,
                **detector_kwargs,
            )
            rcnn_faces = detect_faces(
                "faster-rcnn",
                img,
                **detector_kwargs,
            )

            faces = rcnn_faces if len(rcnn_faces) > len(yolov3_faces) else yolov3_faces
        else:
            faces = detect_faces(args.detector, img, **detector_kwargs)

        print(json.dumps(faces))


if __name__ == "__main__":
    main()
