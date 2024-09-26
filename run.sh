#!/bin/bash

cfg='custom_configs/mask_rcnn/cascade_mask_rcnn_regnetx1.6_fpn_6x_at025_test.py'
weight=./arabidopsis.pth

echo $1
echo $2
echo $3

if [ "$1" = "test" ]; then
    python test.py "$cfg" "$weight"
fi

if [ "$1" = "inference" ]; then
    images=$2
    python inference.py inference "$cfg" "$weight" "$images" "./out/"

fi

if [ "$1" = "visualize" ]; then
    images=$2
    python inference.py visualize "$cfg" "$weight" "$images" "./out/"

fi

