from mmdet.apis import DetInferencer
from glob import glob
import sys


def divide_chunks(l, n):
    # looping till length l
    for i in range(0, len(l), n):
        yield l[i:i + n]


def inference_only(inferencer, files, out, batch_size):
    inferencer(files, out_dir=out, pred_score_thr=0.5, no_save_pred=False, no_save_vis=True, batch_size=batch_size)


def visualize(inferencer, files, out, batch_size, meta_batch_size):
    for batch in divide_chunks(files, meta_batch_size):
        inferencer(batch, out_dir=out, pred_score_thr=0.5, no_save_pred=True, no_save_vis=False, batch_size=batch_size)


if __name__ == '__main__':
    method = sys.argv[1].lower()
    config = sys.argv[2]
    weights = sys.argv[3]
    folder = sys.argv[4]
    out = sys.argv[5]
    files = glob(folder)
    print(f'{len(files)} files')
    # inferencer = DetInferencer(model=config, weights=weights, device='cuda:0', show_progress=True)
    inferencer = DetInferencer(model=config, weights=weights, show_progress=True)

    if method == 'inference':
        inference_only(inferencer, files, out, 1)
    elif method == 'visualize':
        visualize(inferencer, files, out, 1, 10)
    else:
        raise ValueError(f'Method \'{method}\' not supported')
