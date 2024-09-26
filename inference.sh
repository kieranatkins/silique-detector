#!/bin/bash

export images=./test_data/images/*.png
export weight=./arabidopsis.pth

# Generate outputs for phenotyping
export out=./outputs/
python inference.py inference "$cfg_path" "$weight" "$images" "$out"
