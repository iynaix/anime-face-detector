import argparse
import cv2
import json
import warnings
from typing import TypedDict

# disable warnings for mmdet
warnings.filterwarnings("ignore", category=UserWarning)


import anime_face_detector  # noqa: E402


class Face(TypedDict):
    xmin: int
    ymin: int
    xmax: int
    ymax: int


def detect_faces(detector, face_score_threshold, img_path) -> list[Face]:
    # create the detector
    detector = anime_face_detector.create_detector(
        # faster-rcnn is also available
        face_detector_name=detector,
        # "cuda:0" is also available, but takes forever to build
        device="cpu",
    )

    img = cv2.imread(str(img_path))
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
    args = parser.parse_args()

    faces = []
    for img in args.images:
        if args.detector == "best":
            yolov3_faces = detect_faces("yolov3", args.face_score_threshold, img)
            rcnn_faces = detect_faces("faster-rcnn", args.face_score_threshold, img)

            faces = rcnn_faces if len(rcnn_faces) > len(yolov3_faces) else yolov3_faces
        else:
            faces = detect_faces(args.detector, args.face_score_threshold, img)

        print(json.dumps({img: faces}))


if __name__ == "__main__":
    main()
