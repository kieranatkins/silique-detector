#!/bin/bash

export images=./test_images/*.png
export weight=./arabidopsis.pth

# Generate images
export out=./visualisations/
python inference.py visualize "$cfg_path" "$weight" "$images" "$out"
