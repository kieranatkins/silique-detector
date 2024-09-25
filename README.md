# MorphPod: Deep Learning Phenotyping of Arabidopsis Fruit Morphology
Model weights, inference code and phenotyping code associated with the manuscript "Deep Learning Phenotyping of Arabidopsis Fruits with QTL Analysis Verification" by Atkins et al.

Model weights: https://www.dropbox.com/scl/fi/a4zfce27fee0fu21zn6em/arabidopsis.pth?rlkey=dmaukww7kkrsql371oatef677&st=21y2r1qd&dl=0 (must be downloaded to run model)

Running on Mac and Linux can be done using the terminal after installing python. For running on Windows we recommend using WSL Ubuntu (guide: https://learn.microsoft.com/en-us/windows/wsl/install).

Examples of visualisations (generating outputs to draw over image) and inference (generating outputs for analysis) can be found in scripts ``visualisation.sh`` and ``inference.sh``. These scripts invoke the ``inference.py`` python file to either visualise or output the results. The images on which inference will be run is controlled by the variable ``images`` in each script. Once ``inference.sh`` is run and outputs are generated, in order to generate phenotype data the script ``phenotype.sh`` is used, which uses the python ``concurrent`` library for multithreading. 

Requirements:
  - python3
  - torch (A version compatible with mmdet and your hardware - GPU is recommended for large-scale phenotyping, but for testing CPU-only is possible - https://pytorch.org/get-started/locally/)
  - mmengine (python -m pip install mmengine)
  - mmcv v2.1 (Must be compatible with mmdet, we had best success with v2.1, installation details found here - https://mmcv.readthedocs.io/en/latest/get_started/installation.html](https://mmcv.readthedocs.io/en/latest/get_started/installation.html#install-with-pip)
  - mmdet v3.3.0 (Earlier versions may work, at least v3.0, installation details found here - https://mmdetection.readthedocs.io/en/latest/get_started.html)

All extra libraries can be installed using command ``pip install -r requirements.txt``, and are outlined below.

Extra libaries:
  - pandas
  - pycocotools
  - opencv-python
  - scikit-image
  - scipy
  - sknw
  - networkx

# License
This project is released under the [GNU GPL v3](https://www.gnu.org/licenses/gpl-3.0.en.html) licence
