import pathlib
import os

from .detector import LandmarkDetector


def get_config_path(model_name: str) -> pathlib.Path:
    assert model_name in ['faster-rcnn', 'yolov3', 'hrnetv2']

    package_path = pathlib.Path(__file__).parent.resolve()
    if model_name in ['faster-rcnn', 'yolov3']:
        config_dir = package_path / 'configs' / 'mmdet'
    else:
        config_dir = package_path / 'configs' / 'mmpose'
    return config_dir / f'{model_name}.py'


def get_checkpoint_path(model_name: str) -> pathlib.Path:
    assert model_name in ['faster-rcnn', 'yolov3', 'hrnetv2']
    if model_name in ['faster-rcnn', 'yolov3']:
        file_name = f'mmdet_anime-face_{model_name}.pth'
    else:
        file_name = f'mmpose_anime-face_{model_name}.pth'

    return pathlib.Path(os.environ.get("MODEL_PATH")) / file_name


def create_detector(face_detector_name: str = 'yolov3',
                    landmark_model_name='hrnetv2',
                    device: str = 'cuda:0',
                    flip_test: bool = True,
                    box_scale_factor: float = 1.1) -> LandmarkDetector:
    assert face_detector_name in ['yolov3', 'faster-rcnn']
    assert landmark_model_name in ['hrnetv2']
    detector_config_path = get_config_path(face_detector_name)
    landmark_config_path = get_config_path(landmark_model_name)
    detector_checkpoint_path = get_checkpoint_path(face_detector_name)
    landmark_checkpoint_path = get_checkpoint_path(landmark_model_name)
    model = LandmarkDetector(landmark_config_path,
                             landmark_checkpoint_path,
                             detector_config_path,
                             detector_checkpoint_path,
                             device=device,
                             flip_test=flip_test,
                             box_scale_factor=box_scale_factor)
    return model
