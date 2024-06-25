import argparse
import json
import os
import warnings
from typing import TypedDict

# disable warnings for mmdet
warnings.filterwarnings("ignore", category=UserWarning)


import anime_face_detector  # noqa: E402


CUDA_SUPPORT = os.environ.get("CUDA_SUPPORT")


class Face(TypedDict):
    xmin: int
    ymin: int
    xmax: int
    ymax: int
    landmarks: list[tuple[int, int]]


def detect_faces(
    detector,
    img: str,
    *,
    device: str,
    face_score_threshold: float,
    landmark_score_threshold: float
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

        landmarks = []
        for *pt, score in pred["keypoints"]:
            if score >= landmark_score_threshold:
                landmarks.append((int(pt[0]), int(pt[1])))
        # produces negative values sometimes?
        faces.append(
            {
                "xmin": max(0, int(face[0])),
                "ymin": max(0, int(face[1])),
                "xmax": max(0, int(face[2])),
                "ymax": max(0, int(face[3])),
                "landmarks": landmarks,
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
        "--landmark-score-threshold",
        type=float,
        default=0.3,
        help="set the landmark score threshold (default: %(default)s)",
    )
    parser.add_argument(
        "images",
        nargs="+",
        metavar="IMAGES",
        help="List of images to process",
    )
    if CUDA_SUPPORT:
        parser.add_argument(
            "--device",
            type=str,
            default="gpu",
            choices=["gpu", "cpu"],
            help="set the default device (default: %(default)s)",
        )
    args = parser.parse_args()

    detector_kwargs = {
        "face_score_threshold": args.face_score_threshold,
        "landmark_score_threshold": args.landmark_score_threshold,
        "device": args.device if CUDA_SUPPORT else "cpu",
    }
    for img in args.images:
        faces = {}
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

        print(json.dumps(faces, separators=(",", ":")), flush=True)


if __name__ == "__main__":
    main()
