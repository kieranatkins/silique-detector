import pandas as pd
from collections import defaultdict


go_terms = pd.read_csv('./data/genes/fruit_development_go_terms.csv')
go_terms = go_terms[go_terms['exclude'] == False]
# go_terms['type'] = 'fruit development'
go_terms['type'] = 1

go_terms_2 = pd.read_csv('./data/genes/seed_development_go_terms.csv')
go_terms_2 = go_terms_2[go_terms_2['exclude'] == False]
# go_terms_2['type'] = 'seed development'
go_terms_2['type'] = 2

go_terms = pd.concat([go_terms, go_terms_2])
go_terms = go_terms.set_index('child_go_id', verify_integrity=True, drop=False)

goi = ['ER']
data = pd.read_table('./data/genes/ATH_GO_GOSLIM_fixed.csv')

filtered_genes = data[data['go_id'].isin(go_terms['child_go_id'])]
filtered_genes['set'] = filtered_genes.apply(lambda x: go_terms.loc[x['go_id']]['type'], axis=1)

print(filtered_genes)
filtered_genes.to_csv('./out/genes/filtered_genes.csv')
ga = pd.read_csv('./data/genes/gene_association_reduced.csv')
ga = ga.drop_duplicates()
ga = ga.set_index('locus_tair', verify_integrity=True)
genes = pd.read_table('./data/genes/TAIR9_AGI_gene.data')
loci = defaultdict(list)
genes['locus'] = genes.apply(lambda row: row['tair_object'].split('.')[0], axis=1)

for (l, o, c), group in genes.groupby(['locus', 'x', 'chr']):
    loci['locus'].append(l)
    loci['gene_name'].append(ga['locus_name'].get(l, l))
    loci['chr'].append(c)
    loci['orientation'].append(o)
    loci['start'].append(min(group['p1']))
    loci['end'].append(max(group['p2']))

loci = pd.DataFrame(loci)
loci = loci.set_index('locus')

loci['goi'] = loci['gene_name'].isin(goi)

loci.to_csv('./out/genes/all_loci.csv')

data = defaultdict(list)
for i, row in filtered_genes.iterrows():
    try:
        g = loci.loc[row['locus_name']]
    except KeyError:
        print(row['locus_name'])
        continue
    for col in loci.columns:
        data[col].append(g[col])
    for col in filtered_genes.columns:
        data[col].append(row[col])

data = pd.DataFrame(data)
data = data.drop_duplicates()
data.to_csv('./out/genes/filtered_genes.csv')

print(f'{len(data["gene_name"].unique())} unique genes')

# peaks = pd.read_csv('./out/qtl/peaks.csv')
# candidate_genes = []
# distance_to_peak = []
# positions = []
# names = []

# max_dist = 0 # 0 kbs
# # (p1 - d_row['p1'] < max_dist) or (d_row['p2'] - p2 > max_dist)
# for i, row in peaks.iterrows():
#     p, start, end = row['pos_p'], row['ci_lo_p'], row['ci_hi_p']
#     cds = set()
#     dists = {}
#     pos = {}
#     nms = {}
#     for j, d_row in data.iterrows():
#         if ((str(row['chr']) == str(d_row['chr'])) and
#                 ((d_row['start'] > start and d_row['end'] < end) or (start - d_row['start'] < max_dist) or (d_row['end'] - end > max_dist))):
#             cds.add(d_row['locus_name'])
#             nms[d_row['gene_name']] = min(abs(p - d_row['start']), abs(p - d_row['end']))
#             dists[d_row['locus_name']] = min(abs(p - d_row['start']), abs(p - d_row['end']))
#             pos[d_row['locus_name']] = d_row['start'], d_row['end']

#     names.append(sorted(list(nms.items()), key=lambda x:nms[x[0]]))
#     candidate_genes.append(sorted(list(cds), key=lambda x:dists[x]))
#     distance_to_peak.append(sorted(list(dists.items()), key=lambda x:dists[x[0]]))
#     positions.append(sorted(list(pos.items()), key=lambda x:dists[x[0]]))

# # peaks['candidate_genes'] = candidate_genes
# peaks['distance_to_peak'] = distance_to_peak
# peaks['distance_to_genes'] = names
# peaks['positions'] = positions

# peaks.to_csv('./out/genes/peaks_candidates.csv')

