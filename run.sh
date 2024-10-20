#!/bin/bash

cfg='custom_configs/mask_rcnn/cascade_mask_rcnn_regnetx1.6_fpn_6x_at025_test.py'
weight=./arabidopsis.pth

echo $1
echo $2

if [ "$1" = "test" ]; then
    python test.py "$cfg" "$weight"
    exit
fi

if [ "$1" = "inference" ]; then
    images=$2
    python inference.py inference "$cfg" "$weight" "$images" "/data/out"
    exit
fi

if [ "$1" = "visualize" ]; then
    images=$2
    python inference.py visualize "$cfg" "$weight" "$images" "/data/out"
    exit
fi

echo Unrecognised command \"$1\", please select either test, inference for visualize
