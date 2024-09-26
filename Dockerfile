FROM python:3.11

# Device can be either CPU or HW-enabled device like CUDA or ROCm. Default is to install CPU
# In order to find HW-enabled device name visit "https://pytorch.org/get-started/locally/".
# Typically, CUDA binaries will start with "cu" followed by version number without ".".
# For example, CUDA version 11.8 will be "cu118".
# ARG device="cpu" 
ARG device="cu126"

RUN apt-get update && apt-get install ffmpeg libsm6 libxext6  -y
RUN python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/"$device" 
RUN python -m pip install openmim
RUN python -m mim install mmengine
RUN python -m mim install "mmcv==2.1"
RUN git clone https://github.com/open-mmlab/mmdetection.git
WORKDIR /mmdetection
RUN python -m pip install -v -e .
RUN python -c "import mmdet;print(mmdet.__version__)"
RUN pwd


WORKDIR /app
COPY . .

ENTRYPOINT ["./run.sh"]