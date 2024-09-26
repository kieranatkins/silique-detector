import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from matplotlib.ticker import FormatStrFormatter
from scipy import stats

sns.set_theme()

# Data setup
for met in ['mean', 'p95']:
    data = pd.read_csv('phenotype_out_7934899_individuals.csv')
    print(data)
    print(met)
    data['idx'] = data['Unnamed: 0']
    data['Length'] = data[f'length_{met}']
    data['Diameter'] = data[f'diameter_{met}'] 
    data['Volume'] = data[f'volume_{met}']
    data['Area'] = data[f'area_{met}']

    del data['Unnamed: 0']
    print(data.columns)
    cols = ['Length', 'Diameter', 'Volume', 'Area']
    units = ['$mm$', '$mm$', '$mm^2$', '$mm^3$']
    write_y_title = [True, False, True, False]
    melted = pd.melt(data, ['treatment'], cols)
    print(len(melted[melted['treatment'] == 1]))
    print(len(melted[melted['treatment'] == 4]))
    # melted['Treatment'] = melted['treatment']
    melted['Treatment'] = melted.apply(lambda row: 'Isolation' if row['treatment'] == 1 else 'Groups', axis=1)
    print(melted)
    # def go(row):
    #     var = row['variable']
    #     if var == 'Area':
    #         return ''
    #     elif var == 'Volume':
    #         return ''
    #     else:
    #         return 'mm'
    # melted['Unit'] = melted.apply(go, axis=1)
    melted.to_csv(f'{met}.csv')
    # Figures 

    # grid = sns.displot(melted, x='value', col='variable', hue='Treatment', hue_order=['Competition', 'Non-competition'], kind='kde', palette='Set1', facet_kws={'sharey':False, 'sharex':False})
    # grid.set_titles("{col_name}")
    # grid.axes[0][0].set_ylabel('Density', labelpad=10.0)
    # for ax, u in zip(grid.axes[0], units):
    #     ax.set_xlabel(u)
    # plt.savefig(f'./kde_dist_{met}.png', dpi=600)
    plt.close()
    grid = sns.FacetGrid(melted, col='variable', hue='Treatment', height=4, sharex=False, sharey=False, palette='Set1', legend_out=True)
    grid.map_dataframe(sns.violinplot, x='Treatment', y='value')
    grid.set_titles("{col_name}")
    grid.add_legend()
    for ax, u in zip(grid.axes[0], units):
        ax.set_ylabel(u)
        ax.get_xaxis().set_visible(False)
        ax.yaxis.set_major_formatter(FormatStrFormatter('%.1f'))
    plt.subplots_adjust(wspace=0.4)
    plt.savefig(f'./violin_{met}.png', dpi=600)
