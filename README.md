# Deep Learning Phenotyping of Arabidopsis Fruits
Model weights, inference code and phenotyping code associated with the paper "Deep Learning Phenotyping of Arabidopsis Fruits with QTL Analysis Verification" by Atkins et al.

Model weights: https://www.dropbox.com/scl/fi/a4zfce27fee0fu21zn6em/arabidopsis.pth?rlkey=dmaukww7kkrsql371oatef677&st=21y2r1qd&dl=0 

The ``inference.sh`` script can either generate visualisations (silique detections and segmentaions drawn over image) or infer results directly (output results for analysis). An example of both is included in the script, but by default ``inference.sh`` only generates visualisations. The inference script generates outputs from the neural network that then need to be analysed to generate phenotype data. ``phenotype.sh`` does this, by default it is a single-threaded 

Requirements:
  python
  torch
  mmdet v3.3.0 (Earlier versions may work, at least v3.0, installation found here)
