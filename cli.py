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


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--detector",
        type=str,
        default="yolov3",
        choices=["yolov3", "faster-rcnn"],
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

    # create the detector
    detector = anime_face_detector.create_detector(
        # faster-rcnn is also available
        face_detector_name=args.detector,
        # "cuda:0" is also available, but takes forever to build
        device="cpu",
    )

    for img_path in args.images:
        img = cv2.imread(str(img_path))
        faces = []
        for pred in detector(img):
            face = pred["bbox"]
            score = face[4]
            if score < args.face_score_threshold:
                continue

            faces.append(
                {
                    "xmin": int(face[0]),
                    "ymin": int(face[1]),
                    "xmax": int(face[2]),
                    "ymax": int(face[3]),
                }
            )

        print(json.dumps({img_path: faces}))


if __name__ == "__main__":
    main()
