from collections import defaultdict
from pathlib import Path
import pandas as pd
from pprint import pprint
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats
import statsmodels.api as sm
import math
from scipy import stats
import seaborn as sns
import scipy.stats as stats
import math
sns.set_theme()


def IQR(vals):
    q1, q2 = np.quantile(vals, 0.25), np.quantile(vals, 0.75)
    iqr = q2-q1
    v = vals[(vals >= (q1 - (iqr*1.5))) & (vals <= (q2 + iqr*1.5))]
    if len(vals) != len(v):
        print(len(vals), len(v))
    return v

# filename = Path('phenotype_out_7873621.csv')
filename = Path('data/phenotype_out_7934899.csv')
data = pd.read_csv(filename)
data['image'] = data['name']

data = data[data['image'].apply(lambda n: len(n) == 16)]
print(len(data['name'].unique()))
# Generate IDs so pods from the same individual but different images are joined rather than seperated.
data['idx'] = data['name'].apply(lambda n: n[:12])
# data = data[~data['ids'].apply(lambda n: n[6:12]).isin(EXCLUDE_IDS)]

gt = pd.read_csv('data/magic_all.csv')[['line', 'exclude']]
include = gt[gt['exclude'] == 'N']['line']

data['w'] = data.image.str[6:9]
data['mod'] = data.image.str[9]
data['treatment'] = data.image.str[10]
data['rep'] = data.image.str[11]
data['n'] = data.image.str[13:16]
data['id'] = data.image.str[6:12]
data['experiment'] = data.image.str[:5]

data['w'] = '\"' + data['w'] + '\"'
data['id'] = '\"' + data['id'] + '\"'

data['magic_code'] = data.apply(lambda r: int(r['w'].replace('"', '')), axis=1)
data['magic_code'] = data.apply(lambda r: f'MAGIC.{r["magic_code"]}', axis=1)

data['SUBJECT.NAME'] = data['magic_code']
del data['magic_code']
data['pod_length'] = data['length_mm']
data['pod_area'] = data['area_mm2']
data['pod_diameter'] = data['width_mm']
data['pod_volume'] = data['volume_mm3']
data['organ_bbox'] = data['bbox']

print('Proportion of siliques removed due to shape filtering (through connected components / multiple lines)')
print(1.0 - (data[(data['multiple_masks'] == False) & (data['multiple_lengths'] == False)].groupby('id').count() / data.groupby('id').count()).median().mean())

data = data[(data['multiple_masks'] == False) & (data['multiple_lengths'] == False) & (data['score'] > 0.5) & (data['pod_length'] > 0)]

del data['multiple_masks']
del data['multiple_lengths']
data_samples = defaultdict(list)

batch = []
for i, row in data.iterrows():
    if row['name'][:5] == 'AT023':
        batch.append(1)
    elif row['name'][:5] == 'AT024':
        batch.append(2)
    elif row['name'][:5] == 'AT025':
        batch.append(3)

data['batch'] = batch
del_magic = []
for g, group in data.groupby('SUBJECT.NAME'):
    batches = group['batch'].unique()
    if len(batches) > 1:
        del_magic.append(g)
        print(f'Removed {g}')

data = data[~data['SUBJECT.NAME'].isin(del_magic)]
pd.set_option('display.max_columns', None)
print(f'Number of siliques for evaluation: {len(data)}')

# Each individual (might be 1 or multiple images depending on branch number)
for (idx, t, b), group in data.groupby(['idx', 'treatment', 'batch']):
    data_samples['idx'].append(idx)
    data_samples['batch'].append(b)
    data_samples['SUBJECT.NAME'].append(group.iloc[0]['SUBJECT.NAME'])
    data_samples['treatment'].append(t)
    data_samples['pod_count'].append(len(group))
    # data_individuals['pod_count'].append(group['idx'].value_counts().sum())
    data_samples['total_pod_biomass'].append(group['pod_area'].sum())

    axis_max = dict(length=50, area=10, volume=10, diameter=5)

    # Area of an ellipsoid 
    for metric in ['length', 'area', 'volume', 'diameter']:
        v = group[f'pod_{metric}'].sort_values(ascending=True)
        vals = v
        data_samples[f'{metric}_mean'].append(np.mean(vals))
        data_samples[f'{metric}_rsd'].append(np.std(vals / np.mean(vals)))
        n1 = math.floor(len(vals) * 0.9)
        data_samples[f'{metric}_u10'].append(np.median(vals[n1:]))
        data_samples[f'{metric}_p95'].append(np.percentile(vals, 95))

data_samples = pd.DataFrame(data_samples)
print(f'Number of samples for evaluation: {data_samples.shape[0]}')

data_samples = data_samples[data_samples['SUBJECT.NAME'].isin(include)]
data_samples.to_csv(f'data/{filename.stem}_samples.csv')

print(f'Final number of siliques: {data_samples["pod_count"].sum()}')
print(f'Final number of samples: {data_samples.shape[0]}')

cols = ['u10',
        'rsd',
        'mean',
        'p95']

# out = Path('./hists/')
# out.mkdir(exist_ok=True, parents=True)
# individuals = data_individuals.sample(n=100)
# print(individuals)
# for ind in individuals.iterrows():
#     out = Path(f'./cv/{ind["idx"]}')
#     out.mkdir(exist_ok=True, parents=True)
#     for metric in ['length', 'area', 'volume', 'diameter']:
#         for col in cols:
#             p = f'{metric}_{col}'
#             fig, ax = plt.subplots()
#             vals = data_individuals[p]
#             ax.hist(vals)
#             ax.set_title(f'mean={np.mean(vals):.4f}, snd={np.std(vals / np.mean(vals)):.4f}, u10={np.median(vals[n1:])}')
#             fig.savefig(out / f'{p}.png')
#             plt.close(fig)


gt = pd.read_csv('data/magic_all.csv')
gt['ID'] = gt['ID'].apply(lambda n: n.replace('-', '_'))

remove_idxs = []
data_lines = defaultdict(list)
for (m, t, b), group in data_samples.groupby(['SUBJECT.NAME', 'treatment', 'batch']):
    idx = group['idx']
    # if len(group) < 3:
        # remove_idxs.extend(idx.tolist())
        # continue
    data_lines['SUBJECT.NAME'].append(m)
    data_lines['batch'].append(b)
    data_lines['treatment'].append(t)
    data_lines['pod_count'].append(np.mean(group[f'pod_count'].values))
    # data_averages['harvest_index'].append(np.mean(group[f'harvest_index'].values))
    data_lines['pod_biomass'].append(np.mean(group[f'total_pod_biomass'].values))
    # val = (gt[gt['ID'] == idx]['sil_plant'].values)
    # val = val[0] if len(val) > 0 else math.nan
    # data_averages['pod_biomass_inferred'].append(group['area_median'].mean() * val)
    # data_averages['harvest_index_inferred'].append(
    #     (group['area_median'].mean() * val) / group['total_pod_biomass'].mean())
    for metric in ['length', 'area', 'diameter', 'volume']:
        for col in cols:
            data_lines[f'{metric}_{col}'].append(np.mean(group[f'{metric}_{col}'].values))

data_lines = pd.DataFrame(data_lines)
data_lines['treatment'] = data_lines['treatment'].apply(lambda x: int(x))
# for m, group in data_averages.groupby('SUBJECT.NAME'):
    # if not ((group['treatment'] == 1).any() & (group['treatment'] == 4).any()):
        # remove_idxs.append(m)

print(f'Removed {remove_idxs}')
data_lines = data_lines[~data_lines['SUBJECT.NAME'].isin(remove_idxs)]
# del data_averages['harvest_index_inferred']
# del data_averages['pod_biomass_inferred']

# Stats
for p in ['length', 'diameter', 'volume', 'area']:
    for col in cols:
        c = f'{p}_{col}'
        t1 = data_lines[data_lines['treatment'] == 1][c]
        t4 = data_lines[data_lines['treatment'] == 4][c]
        print(f'{c}: {stats.ttest_rel(t1, t4).pvalue}')

data_lines.to_csv(f'data/{filename.stem}_lines.csv')
