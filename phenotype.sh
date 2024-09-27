#!/bin/bash

out=./out/preds

# For running with MPI on slurm
# mpiexec -n $SLURM_NTASKS python -m mpi4py.futures phenotype_slurm.py "$out" --scale=1.0

# Running with python concurrent library
python phenotype.py "$out" --scale=1.0


