import cv2
import numpy as np
import warnings
from scipy import ndimage
from skimage import morphology
import sknw
import logging
import networkx as nx
import alphashape


warnings.filterwarnings("ignore", category=UserWarning)


# Takes the output masks from the network and returns a list with position of each element
# corresponding to each instances length, perimeter, area and pseudo width.
# mask :: numpy array of type uint8
# length_contours :: Bool - return the contour object for display
def mask_analysis(mask, scale, id, pixel_vals=False, multiple_masks=False, multiple_lengths=False, length_contours=False, calc_perim=True):
    # Find coordinates of mask bounding box
    coords = np.argwhere(mask)

    # if there is no mask, very small mask (< 64 pixels)
    if coords.size < 64:
        # print('Empty/Unsuitable mask found, skipping...')
        length_px, perimeter_px, area_px2, width_px, width_m_px, volume_px3 = 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
        m_masks = False
        m_lengths = False
    else:
        x_min, y_min = coords.min(axis=0)
        x_max, y_max = coords.max(axis=0)
        mask = mask[x_min:x_max + 1, y_min:y_max + 1]

        # Pod length
        skel = morphology.skeletonize(mask)
        graph = sknw.build_sknw(skel)
        bad_edges = [(u, v) for u, v in graph.edges() if graph[u][v]['weight'] < 5]
        graph.remove_edges_from(bad_edges)

        # length_px = max([data['weight'] for s, t, data in graph.edges(data=True)])

        all_lengths = nx.all_pairs_dijkstra_path_length(graph, weight='weight')
        length_px = max([max(length_dict.values()) for t, length_dict in all_lengths])
        m_lengths = True if nx.number_of_edges(graph) > 1 else False

        # Pod width
        dist = ndimage.morphology.distance_transform_edt(mask)
        distances = []
        for y, x in np.argwhere(skel):
            distances.append(dist[y, x])

        width_px = max(distances, default=0) * 2
        width_m_px = np.nan_to_num(np.median(distances))

        mask = mask * 255

        # Find contours of standard mask
        contours, _ = cv2.findContours(mask, cv2.RETR_TREE, cv2.CHAIN_APPROX_NONE)

        # Pod perimeter & mask count
        m_masks = True if len(contours) > 1 else False

        if calc_perim:
            perimeter_px = max([cv2.arcLength(c, True) for c in contours], default=0.0)

        distances = np.array(distances)
        volume_px3 = np.sum((np.pi * (distances ** 2)))

        # Pod area
        area_px2 = sum([cv2.contourArea(c) for c in contours])

    area_mm2 = float(area_px2 / (scale ** 2))
    perimeter_mm = float(perimeter_px / scale)
    length_mm = float(length_px / scale)
    width_mm = float(width_px / scale)
    width_m_mm = float(width_m_px / scale)
    volume_mm3 = float(volume_px3 / (scale ** 3))

    ret = [[length_mm, perimeter_mm, width_mm, width_m_mm, area_mm2, volume_mm3]]
    if pixel_vals:
        ret.append([length_px, perimeter_px, width_px, width_m_px, area_px2, volume_px3])
    if multiple_masks:
        ret.append(m_masks)
    if multiple_lengths:
        ret.append(m_lengths)
    if length_contours:
        ret.append(contours)
    # print(ret, flush=True)
    return ret


# Mask analysis helper function to facilitate multiprocessing
def _ma(mask, scale):
    mask = mask.to('cpu').numpy() * 255
    mask = mask.astype(np.uint8)

    measurement, multiple_masks = mask_analysis(mask, scale, multiple_masks=True)
    measurement.append(multiple_masks)

    return measurement
