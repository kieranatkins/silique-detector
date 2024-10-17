# QTL Analysis 
This folder contains the code and data associated with the QTL analysis. The script `get_genes.py` reads the TAIR9 dataset and list of gene ontologies of interest and filters them into a list of candidate genes, named `filtered genes` in `out`.

`prepare_data.py` reads the outputs of the model and creates line-level metrics of the MAGIC arabidopsis population

`qtl_v2.r` reads the output created by the `prepare_data.py` and performs the QTL analysis, outputting figures and a `.csv` file of the peaks.


