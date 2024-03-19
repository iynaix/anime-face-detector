# anime-face-detector

anime-face-detector is a simple cli interface to [hyst's anime-face-detector](https://github.com/hysts/anime-face-detector)

## Why
[anime-face-detector](https://github.com/hysts/anime-face-detector) has not been updated in some time, and major new releases of `mmcv`, `mmdet` and `mmpose` have caused breaking changes.

This project serves to provide a working version of all the dependencies required to reproducibly build `anime-face-detector` via **nix flakes** and provide a cli interface that can be utilized by other programming languages.

Unfortunately, I do not have enough knowledge of machine learning to figure out how to port the project to the new `mmcv` version. If you do, please [submit a PR](https://github.com/hysts/anime-face-detector/pulls), it will be very much appreciated! 🙏

## Installation

Add the following input to your `flake.nix`
```nix
{
  # do not override this flake's nixpkgs snapshot!
  inputs.anime-face-detector.url = "github:iynaix/anime-face-detector";
}
```
Then, include it in your `environment.systemPackages` or `home.packages` by referencing the input:

```
inputs.anime-face-detector.packages.<system>.default
```

or with cuda support:
```
inputs.anime-face-detector.packages.<system>.with-cuda
```

Alternatively, it can also be run directly:

```
nix run github:iynaix/anime-face-detector -- /path/to/image
```

or with cuda support:
```
nix run github:iynaix/anime-face-detector#with-cuda -- /path/to/image
```

#### NOTE: cuda support might take a while to build, please be patient. :)

## Usage

```console
$ anime-face-detector --help
usage: anime-face-detector [-h] [--detector {best,yolov3,faster-rcnn}] [--face-score-threshold FACE_SCORE_THRESHOLD]
                           [--landmark-score-threshold LANDMARK_SCORE_THRESHOLD] [--device {gpu,cpu}]
                           IMAGES [IMAGES ...]

positional arguments:
  IMAGES                List of images to process

options:
  -h, --help            show this help message and exit
  --detector {best,yolov3,faster-rcnn}
                        choose the detector to use (default: best)
  --face-score-threshold FACE_SCORE_THRESHOLD
                        set the face score threshold (default: 0.5)
  --landmark-score-threshold LANDMARK_SCORE_THRESHOLD
                        set the landmark score threshold (default: 0.3)
  --device {gpu,cpu}    set the default device (default: gpu)
```

### Sample Output
```console
$ anime-face-detector ~/Pictures/Wallpapers/image1.png ~/Pictures/Wallpapers/image2.png
[{"xmin":3213,"ymin":1197,"xmax":4567,"ymax":2576,"landmarks":[[3265,1589],[3372,2006],[3698,2504],[4495,2251],[4649,1869],[3318,1331],[3435,1368],[3582,1401],[4048,1355],[4276,1378],[4468,1434],[3317,1483],[3449,1468],[3602,1616],[3372,1692],[3449,1741],[3547,1736],[4044,1631],[4265,1656],[4432,1773],[4067,1798],[4203,1867],[4339,1870],[3596,2024],[3569,2157],[3655,2218],[3798,2288],[3658,2231]]}]
[{"xmin":1372,"ymin":418,"xmax":1801,"ymax":837,"landmarks":[[1415,534],[1410,652],[1516,803],[1631,783],[1722,693],[1516,477],[1564,496],[1611,522],[1704,591],[1733,602],[1755,618],[1448,522],[1507,528],[1555,571],[1452,571],[1485,586],[1522,595],[1662,636],[1705,645],[1724,677],[1636,675],[1657,693],[1680,703],[1622,698],[1547,725],[1559,727],[1571,734],[1557,732]]}]
```

## Hacking
Use `nix develop` for the default devenv using cpu, and `nix develop .#cuda` for the devenv with cuda support.