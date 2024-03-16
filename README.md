# anime-face-detector

anime-face-detector is a simple cli interface to hyst's [anime-face-detector](https://github.com/hysts/anime-face-detector)

## Why
[anime-face-detector](https://github.com/hysts/anime-face-detector) has not been updated in some time, and major new releases of `mmcv`, `mmdet` and `mmpose` have caused breaking changes.

This project serves to provide a working version of all the dependencies required to reproducibly build `anime-face-detector` via **nix** and provide a cli interface that can be utilized with other programming languages.

Unfortunately, I do not have enough knowledge of machine learning to figure out how to port the project to the new `mmcv` version. If you do, please [submit a PR](https://github.com/hysts/anime-face-detector/pulls), it will be very much appreciated! 🙏

## Installation

Add the following input to your `flake.nix`
```nix
{
  # do not override this repo's nixpkgs snapshot!
  inputs.anime-face-detector.url = "github:iynaix/anime-face-detector";
}
```
Then, include it in your `environment.systemPackages` or `home.packages` by referencing the input:

```
inputs.nh.packages.<system>.default
```

Alternatively, it can also be run directly:

```
nix run github:iynaix/anime-face-detector -- /path/to/image
```

## Usage

```console
$ anime-face-detector --help
usage: anime-face-detector [-h] [--detector {yolov3,faster-rcnn}] [--face-score-threshold FACE_SCORE_THRESHOLD] IMAGES [IMAGES ...]

positional arguments:
  IMAGES                List of images to process

options:
  -h, --help            show this help message and exit
  --detector {yolov3,faster-rcnn}
                        choose the detector to use (default: yolov3)
  --face-score-threshold FACE_SCORE_THRESHOLD
                        set the face score threshold (default: 0.5)
```

### Sample Output
```console
$ anime-face-detector ~/Pictures/Wallpapers/image1.png ~/Pictures/Wallpapers/image2.png
[{"xmin": 1514, "ymin": 559, "xmax": 1900, "ymax": 930}]
[{"xmin": 1388, "ymin": 1142, "xmax": 1874, "ymax": 1631}]
```

## Hacking
Just use `nix develop`