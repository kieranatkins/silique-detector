# MorphPod: Deep Learning Phenotyping of Arabidopsis Fruit Morphology
Model weights, inference code and phenotyping code associated with the manuscript "Deep Learning Phenotyping of Arabidopsis Fruits with QTL Analysis Verification" by Atkins et al.

Model weights: https://www.dropbox.com/scl/fi/a4zfce27fee0fu21zn6em/arabidopsis.pth?rlkey=dmaukww7kkrsql371oatef677&st=21y2r1qd&dl=0

# Using docker
We provide a docker container to reproduce the test results, along with the test images and annotations in this repository for convenience (the full dataset is available at DOI:10.20391/283ce324-6a96-4cc8-8168-51f48354f7cf). testing takes approximately 30 minutes (inc. build time) on an Intel Ultra 7 165U. We also provide capability of generating outputs on novel data using the ``inference`` and ``visualize`` options. 

**Step 1:**
Download model weights ``arabidopsis.pth`` and place in directory. Once complete, build docker container.
```
docker build -t silique-detector .
```
**OR**

We provide a pre-built docker [here](https://hub.docker.com/repository/docker/kieranatkins/silique-detector/general]). This can be pulled using:
```
docker pull kieranatkins/silique-detector
```
Note the full image name with have to be provided when running. (i.e. ``docker run --shm-size=512m kieranatkins/silique-detector test``).

**Step 2:**
This docker container has three primary functions. ``test``, ``inference`` and ``visualize``. ``test`` will rerun the Segmentation and Detection AP results of the test data in the folder ``test_data``. This is the same test data in the main dataset, placed here for convenience.

```
docker run --shm-size=512m silique-detector test
```

To geneare outputs on images outside the container, use the ``inference`` option and mount your own data folder to the container using -v flag: e.g.
```
docker run -v path/to/my_data:/data --shm-size=512m silique-detector inference "/data/images/*.png"
```
Or the ``visualize`` option to draw outputs over images: e.g.
```
docker run -v path/to/my_data:/data --shm-size=512m silique-detector visualize "/data/images/*.png"
```
These options can also be run on the test data included in the container. e.g.
```
docker run -v ./test_data:/data --shm-size=512m silique-detector visualize "/data/images/*.png"
```
Outputs are placed in the data directory, in a folder named ``out``. Once inference outputs are generated, the script ``phenotype.sh`` can be used to generate pod morphology data. This uses the python ``concurrent`` library for multithreading. 

We provide experimental CUDA support for the docker image (requires building the image): Edit ``device`` parameter at top of the ``Dockerfile`` so ``device=cu121``. Currently only supports CUDA drivers compatible with toolkit v12.1. For running on Ubuntu, install ``nvidia-container-toolkit`` and follow steps [here](https://stackoverflow.com/questions/59691207/docker-build-with-nvidia-runtime). Adding the flag ``--gpus all`` whenever running ``docker run`` lines to allow GPU passthrough.

# Running locally
Running on Mac and Linux can be done using the terminal after installing python. For running on Windows we recommend using WSL Ubuntu (guide: https://learn.microsoft.com/en-us/windows/wsl/install).

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

The ``inference.sh`` script can be used to generate model outputs, with the ``images`` variable controlling the images to be phenotyped ``weight`` the location of the ``arabidopsis.pth`` weight file and ``out`` controlling where outputs will be saved.

# Generating phenotype data
Once ``inference`` has been used to create model outputs, the script ``phenotype.sh`` then phenotypes the output and creates a ``.csv`` file. The ``data`` variable controls where the outputs created by inference are stored. The script uses the python ``concurrent`` library for multithreading. There is also an included ``--scale`` parameter to tell the script the scale of the image (in mm/pixel), the script then outputs the values in both their pixel units and in the correct mm, mm2 and mm3 units. The script outputs silique length, diameter, volume approximation and area.

# QTL analysis
The directory ``qtl_analysis`` contains the data and code used to perform the QTL analysis outlined in the paper, as well as generating figures.

# License
This project is released under the [GNU GPL v3](https://choosealicense.com/licenses/gpl-3.0/) license
