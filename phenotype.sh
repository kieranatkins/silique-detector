#!/bin/bash

# For running with MPI on slurm
# mpiexec -n $SLURM_NTASKS python -m mpi4py.futures phenotype_slurm.py \
# ./outputs/preds \
# --scale=1.0

# Running with python concurrent library
python phenotype.py \
./out/preds \
--scale=1.0


