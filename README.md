# MorphPod: Deep Learning Phenotyping of Arabidopsis Fruit Morphology
Model weights, inference code and phenotyping code associated with the manuscript "Deep Learning Phenotyping of Arabidopsis Fruits with QTL Analysis Verification" by Atkins et al.

Model weights: https://www.dropbox.com/scl/fi/a4zfce27fee0fu21zn6em/arabidopsis.pth?rlkey=dmaukww7kkrsql371oatef677&st=21y2r1qd&dl=0 (must be downloaded to run model)

# Using docker
We provide a docker container to reproduce the test results, along with the test images and annotations in this repository for convenience (the full dataset is available at DOI:10.20391/283ce324-6a96-4cc8-8168-51f48354f7cf). testing takes approximately 30 minutes (inc. build time) on an Intel Ultra 7 165U. We also provide capability of generating outputs on novel data using the ``inference`` and ``visualize`` options. 

Step 1:
Download model weights ``arabidopsis.pth`` and place in directory. Once complete, build docker container.
```
docker build -t silique_detector .
```
If using CUDA:
Edit ``device`` parameter at top of the ``Dockerfile`` so ``device=cu121``. Currently only supports CUDA drivers compatible with toolkit v12.1. For running on Ubuntu, install ``nvidia-container-toolkit`` and follow steps [here](https://stackoverflow.com/questions/59691207/docker-build-with-nvidia-runtime). Adding the flag ``--gpus all`` whenever running ``docker run`` lines to allow GPU passthrough.


Step 2:
This docker container has three primary functions. The first ``test`` will rerun the Segmentation and Detection AP results of the test data in the folder ``test_data``. This is the same test data in the main dataset, placed here for convenience.

```
docker run --shm-size=512m silique_detector test
```
The docker container can also generate outputs and visualisations on novel data. Data must be placed within this directory before building. This can be run with either:

```
docker run --shm-size=512m silique_detector inference ./test_data/images/*.png
```
or
```
docker run --shm-size=512m silique_detector visualize ./test_data/images/*.png
```
For inference (generating outputs) or visualizations (generating outputs and overlaying on images) respectively.

Step 3:
Outputs of both of these must be retrieved using command:
```
docker cp silique_detector:/app/out ./out/
```

Once outputs are generated, in order to generate phenotype data the script ``phenotype.sh`` is used, which uses the python ``concurrent`` library for multithreading. 

# Installing locally
Running on Mac and Linux can be done using the terminal after installing python. For running on Windows we recommend using WSL Ubuntu (guide: https://learn.microsoft.com/en-us/windows/wsl/install).

Examples of visualisations (generating outputs to draw over image) and inference (generating outputs for analysis) can be found in scripts ``visualisation.sh`` and ``inference.sh``. These scripts invoke the ``inference.py`` python file to either visualise or output the results. The images on which inference will be run is controlled by the variable ``images`` in each script. Once ``inference.sh`` is run and outputs are generated, in order to generate phenotype data the script ``phenotype.sh`` is used, which uses the python ``concurrent`` library for multithreading. 

Requirements:
  - python3
  - torch (A version compatible with mmdet and your hardware - GPU is recommended for large-scale phenotyping, but for testing CPU-only is possible - https://pytorch.org/get-started/locally/)
  - mmdet v3.3.0 (Earlier versions may work, at least v3.0, installation details found here - https://mmdetection.readthedocs.io/en/latest/get_started.html. We found best results with mmcv==2.1)

All extra libraries can be installed using command ``pip install -r requirements.txt``, and are outlined below.

Extra libaries:
  - pandas
  - pycocotools
  - opencv-python
  - scikit-image
  - scipy
  - sknw
  - networkx

# QTL analysis
The directory ``qtl_analysis`` contains the data and code used to perform the QTL analysis outlined in the paper, as well as generating figures.

# License
This project is released under the [GNU GPL v3](https://choosealicense.com/licenses/gpl-3.0/) license
