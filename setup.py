#!/usr/bin/env python3

from setuptools import setup, find_packages

setup(
    name="anime-face-detector",
    version="1.0",
    # Modules to import from other scripts:
    packages=find_packages(
        include=[
            "anime_face_detector",
            "anime_face_detector.*",
        ]
    ),
    # Executables
    scripts=["cli.py"],
    entry_points={
        "console_scripts": [
            "anime-face-detector=cli:main",
        ],
    },
)
