FROM python:3.11


RUN apt-get update && apt-get install ffmpeg libsm6 libxext6  -y
RUN python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu 
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
WORKDIR /app/src

CMD python test.py custom_configs/mask_rcnn/cascade_mask_rcnn_regnetx1.6_fpn_6x_at025_test.py ./arabidopsis.pth


