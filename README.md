# MorphPod: Deep learning phenotyping of Arabidopsis fruit morphology 
Model weights, inference code and phenotyping code associated with the manuscript "Unlocking the Power of AI for Phenotyping Fruit Morphology in Arabidopsis" by Atkins et al.

Model weights: https://www.dropbox.com/scl/fi/a4zfce27fee0fu21zn6em/arabidopsis.pth?rlkey=dmaukww7kkrsql371oatef677&st=21y2r1qd&dl=0

# Using docker
We provide a docker container to reproduce the test results, along with the test images and annotations in this repository for convenience.

**Step 1:**
Download this repository and model weights ``arabidopsis.pth``, then place ``arabidopsis.pth`` in the downloaded directory. Once complete, build docker container.
```
docker build -t silique-detector .
```
**OR**

We provide a pre-built docker image [here](https://hub.docker.com/repository/docker/kieranatkins/silique-detector/). This can be pulled using:
```
docker pull kieranatkins/silique-detector
```
Note: The full image name must be provided when running the pre-built image. (i.e. ``docker run --shm-size=512m kieranatkins/silique-detector test``).

**Step 2:**
This docker container has three primary functions. ``test``, ``inference`` and ``visualize``. The ``test`` function re-runs the Detection and Segmentation AP tests on the data inside folder ``test_data`` from the associated manuscript, provided in the docker image for convenience. ``inference`` detects and segments siliques in the images of a given path, where the ``phenotype.sh`` script can then be used to generate pod morphological data. ``visualize`` detects and segments siliques in the images of a given path, but then draws those detections and segmentations over the images to visualize what the model has detected.

To run ``test``:
```
docker run --shm-size=512m silique-detector test
```
To run ``inference`` your own data must be mounted to the docker container's ``/data`` directory using the -v flag (e.g. ``-v /path/to/my_data:/data``). Once your data has been mounted to the ``/data`` directory in the docker image, your data can be accessed by the software (e.g. ``"/data/*.png"`` if your images are .png images)  
```
docker run -v /path/to/my_data:/data --shm-size=512m silique-detector inference "/data/*.png"
```
The ``visualize`` function is similar to the ``inference`` function, the function name only needs changing: e.g.
```
docker run -v /path/to/my_data:/data --shm-size=512m silique-detector visualize "/data/*.png"
```
These options can also be run on the test data included in the container. e.g.
```
docker run -v $(pwd):/data --shm-size=512m silique-detector visualize "./test_data/images/*.png"
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
