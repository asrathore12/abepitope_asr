# AbEpiTope GPU Setup & Usage

This repository contains scripts to **set up the environment** and **run AbEpiTope** on a GPU server (e.g., UAB Cheaha with NVIDIA A100).  
It does **not** contain raw structure data — you provide your own PDB or mmCIF files.

---

## 🔧 Environment Setup

### 1. Clone this repository
```bash
git clone https://github.com/asrathore12/abepitope_asr.git
cd abepitope_asr



### 2. Run the setup script
This will create a conda environment (inverse) with:
Python 3.9
GPU-enabled PyTorch (CUDA 12.1)
PyTorch Geometric (scatter, sparse, cluster, spline)
AbEpiTope 1.0

```bash
bash setup_abepitope_gpu.sh


Usage

### 1. Activate the environment
Run this every time before using AbEpiTope:
```bash
source ~/miniconda3/etc/profile.d/conda.sh
conda activate inverse

### 2. Run AbEpiTope on your structure
Use the helper script:

```bash
python run_abepitope.py \
    --input /path/to/your_structure.pdb \
    --outdir ./output

Arguments:
--input → PDB or mmCIF file containing antigen + antibody chains
--outdir → directory where results will be written

Outputs

After running, you’ll find in --outdir:
interface.csv → interface residues/features
output.csv → epitope/paratope prediction scores
abag_sequence_data.fasta → antigen/antibody sequences
























