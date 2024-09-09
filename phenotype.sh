#!/bin/bash

# For running with MPI on slurm
# mpiexec -n $SLURM_NTASKS python -m mpi4py.futures phenotype_slurm.py \
# ./outputs/preds \
# --scale=1.0

# Running without MPI multiprocessing
python phenotype.py \
./outputs/preds \
--scale=1.0


