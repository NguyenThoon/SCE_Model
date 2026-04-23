#!/bin/bash -l

#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=60G
#SBATCH --time=0-2:00:00
#SBATCH --mail-type=ALL
#SBATCH --job-name="TN_job_test"
#SBATCH -p short_gpu
#SBATCH --gpus-per-task=1

hostname
echo "Time: $(date)"
source /etc/profile.d/modules.sh

module purge
module load cmake
module load cuda/11.4
module load gcc/9.2.1
module load extra
module load openmpi/4.1.2_slurm-21.08.5

cd /rhome/tnguy1340/sce_test/SCE_Model || exit 1

echo "PWD: $(pwd)"
ls -l ./bin/runDiscSimulation_M
strings ./bin/runDiscSimulation_M | grep "DEBUG: tissueCenter size" || exit 1

./build_EpiScale_Signal.sh build || exit 1

echo "After build:"
ls -l ./bin/runDiscSimulation_M
strings ./bin/runDiscSimulation_M | grep "DEBUG: tissueCenter size" || exit 1

./bin/runDiscSimulation_M