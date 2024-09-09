#!/bin/bash

export images=./test_images/*.png
export weight=./epoch_36.pth

# Generate outputs for phenotyping
# export out=./outputs/
# python inference.py inference "$cfg_path" "$weight" "$images" "$out"

# Generate images
export out=./visualisations/
python inference.py visualize "$cfg_path" "$weight" "$images" "$out"
