#!/bin/bash
# ==============================================================
# setup_abepitope_gpu.sh
# Environment setup script for AbEpiTope on GPU (Cheaha / HPC)
# ==============================================================

# --- CONFIG ---------------------------------------------------
ENV_NAME="abepitope_gpu"
PYTHON_VERSION="3.9"
TORCH_VERSION="2.1.2"
TORCHVISION_VERSION="0.16.2"
TORCHAUDIO_VERSION="2.1.2"
PYTORCH_CUDA_VERSION="12.1"   # works with CUDA driver 12.4 on Cheaha
# --------------------------------------------------------------

echo ">>> Loading conda..."
source ~/miniconda3/etc/profile.d/conda.sh || {
  echo "Conda not found. Please install Miniconda first."
  exit 1
}

# --------------------------------------------------------------
# 1) Create conda environment
# --------------------------------------------------------------
echo ">>> Creating conda environment: $ENV_NAME"
conda create -y -n $ENV_NAME python=$PYTHON_VERSION
conda activate $ENV_NAME || { echo "Failed to activate env"; exit 1; }

# --------------------------------------------------------------
# 2) Install PyTorch with GPU support
# --------------------------------------------------------------
echo ">>> Installing PyTorch + CUDA..."
conda install -y -c pytorch -c nvidia \
  pytorch=$TORCH_VERSION torchvision=$TORCHVISION_VERSION torchaudio=$TORCHAUDIO_VERSION \
  pytorch-cuda=$PYTORCH_CUDA_VERSION

# --------------------------------------------------------------
# 3) Install PyTorch Geometric dependencies
# --------------------------------------------------------------
echo ">>> Installing PyTorch Geometric (scatter, sparse, cluster, spline)..."
conda install -y -c pyg -c conda-forge \
  pytorch-scatter pytorch-sparse pytorch-cluster pytorch-spline-conv

# --------------------------------------------------------------
# 4) Install AbEpiTope and supporting packages
# --------------------------------------------------------------
echo ">>> Installing AbEpiTope and dependencies..."
pip install abepitope biotite pandas

# --------------------------------------------------------------
# 5) Final check
# --------------------------------------------------------------
echo ">>> Checking installation..."
python - <<'PY'
import torch
print("Torch version:", torch.__version__)
print("torch.version.cuda:", torch.version.cuda)
print("CUDA available?:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("Device:", torch.cuda.get_device_name(0))
import abepitope
print("AbEpiTope import OK")
PY

echo ">>> Setup complete!"
echo "Activate with: conda activate $ENV_NAME"
