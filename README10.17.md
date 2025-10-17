# AbEpiTope-1.0 on Cheaha (GPU) — QuickStart

Small, runnable chunks to get **AbEpiTope-1.0** working on Cheaha using a lightweight Python **virtualenv** (no user conda envs needed). This guide installs a CUDA-enabled PyTorch stack, PyTorch Geometric, AbEpiTope, and its deps; it also covers HMMER and a Slurm example.

---

## 0) (Optional) get a GPU shell

If you’re not already on a GPU node, request an interactive session (adjust partition/QOS):

```bash
salloc --partition=<GPU_PARTITION> --gres=gpu:1 --time=02:00:00
```

---

## 1) Load Cheaha modules (per session)

```bash
module purge
module load shared rc-base
module load Anaconda3/2023.07-2
```

Why: this provides a clean Python 3.11 toolchain without touching system Python.

---

## 2) Create & activate a dedicated venv (once; then reuse)

```bash
python -m venv ~/abepi_venv
source ~/abepi_venv/bin/activate
python -V; which python
```

Expected: `Python 3.11.x` and `~/abepi_venv/bin/python`.

> Re-activate in future sessions:
>
> ```bash
> module purge && module load shared rc-base && module load Anaconda3/2023.07-2
> source ~/abepi_venv/bin/activate
> ```

---

## 3) Install CUDA-enabled PyTorch 2.1.2 (cu121)

```bash
pip install --no-cache-dir torch==2.1.2+cu121   --extra-index-url https://download.pytorch.org/whl/cu121
```

Add matching `torchvision` and `torchaudio`:

```bash
pip install --no-cache-dir torchvision==0.16.2+cu121 torchaudio==2.1.2+cu121   --extra-index-url https://download.pytorch.org/whl/cu121
```

Pin numeric basics tested to work:

```bash
pip install --no-cache-dir "numpy==1.26.4" "pillow==10.3.0"
```

---

## 4) Install PyTorch Geometric CUDA wheels (cu121)

```bash
pip install --no-cache-dir torch_scatter torch_sparse torch_cluster torch_spline_conv   -f https://data.pyg.org/whl/torch-2.1.0+cu121.html
pip install --no-cache-dir torch_geometric==2.6.1
```

---

## 5) Install AbEpiTope + deps

```bash
# AbEpiTope + pandas
pip install --no-cache-dir "git+https://github.com/mnielLab/AbEpiTope-1.0.git" pandas==2.2.2

# Bio libs + ESM (pin biotite for ESM-IF1 compatibility)
pip install --no-cache-dir biopython "biotite<0.39" fair-esm==2.0.0
```

> **Do not upgrade `biotite`** in this environment; `0.38.x` is required for ESM-IF1 compatibility.

---

## 6) Ensure HMMER (`hmmsearch`) exists

Try Cheaha module first:

```bash
module spider HMMER
# choose a listed version, e.g.:
module load HMMER/3.3.2-iimpi-2020b
which hmmsearch || echo "no hmmsearch yet"
```

If your site module isn’t available, use a tiny fallback env that only provides the HMMER binaries (one-time create):

```bash
conda create -y -n hmmertools -c bioconda -c conda-forge hmmer=3.3.2
```

Then prepend its `bin` to your `PATH` (every session you run AbEpiTope):

```bash
export PATH="$HOME/miniconda3/envs/hmmertools/bin:$PATH"
which hmmsearch && hmmsearch -h | head -n 3
```

---

## 7) (Optional) cache ESM weights in your home

```bash
export TORCH_HOME="$HOME/.cache/torch"
mkdir -p "$TORCH_HOME"
```

---

## 8) Sanity checks

GPU + versions:

```bash
python - <<'PY'
import torch, torchvision
print("torch:", torch.__version__, "cu:", torch.version.cuda, "cuda:", torch.cuda.is_available())
if torch.cuda.is_available(): print("gpu:", torch.cuda.get_device_name(0))
print("torchvision:", torchvision.__version__)
PY
```

Imports:

```bash
python - <<'PY'
import pkgutil
mods = ["torch","torchvision","torchaudio","torch_geometric",
        "torch_scatter","torch_sparse","torch_cluster","torch_spline_conv",
        "abepitope","pandas","biotite","Bio","esm"]
print({m:("OK" if pkgutil.find_loader(m) else "missing") for m in mods})
PY
```

HMMER:

```bash
which hmmsearch && hmmsearch -h | head -n 3
```

---

## 9) Run AbEpiTope (single file or directory)

Single file example (change the path to your CIF/PDB):

```bash
python - <<'PY'
from pathlib import Path
from abepitope.main import StructureData, EvalAbAgs

STRUCTUREINPUTS = Path.home() / "alphafold_1a14.cif"    # or a directory of pdb/cif files
ENCDIR = Path.cwd() / "encodings"
TMPDIR = Path.cwd() / "temporary"
OUTDIR = Path.cwd() / "output"
for d in (ENCDIR, TMPDIR, OUTDIR): d.mkdir(exist_ok=True)

data = StructureData()
# default interface distance 4.0 Å; change with atom_radius=4.5 if desired
data.encode_proteins(STRUCTUREINPUTS, ENCDIR, TMPDIR)

eval_abags = EvalAbAgs(data, device="cuda")
eval_abags.predict(OUTDIR)
print("Results ->", OUTDIR.resolve())
PY
```

Outputs appear under `./output`.

> The ESM warning about “Regression weights not found” for contacts is expected and harmless here.

---

## 10) Start-of-session recipe (what to run every time)

```bash
module purge
module load shared rc-base
module load Anaconda3/2023.07-2
source ~/abepi_venv/bin/activate
# (only if you used the HMMER fallback env)
export PATH="$HOME/miniconda3/envs/hmmertools/bin:$PATH"
# (optional but nice)
export TORCH_HOME="$HOME/.cache/torch"
```

---

## 11) Slurm batch template (optional)

```bash
cat > run_abepitope.sbatch <<'SB'
#!/bin/bash
#SBATCH --job-name=abepi
#SBATCH --gres=gpu:1
#SBATCH --time=04:00:00
#SBATCH --mem=32G
#SBATCH --partition=<GPU_PARTITION>   # set to your cluster's GPU partition

module purge
module load shared rc-base
module load Anaconda3/2023.07-2
source ~/abepi_venv/bin/activate
# if using the HMMER fallback env:
export PATH="$HOME/miniconda3/envs/hmmertools/bin:$PATH"
export TORCH_HOME="$HOME/.cache/torch"

python - <<'PY'
from pathlib import Path
from abepitope.main import StructureData, EvalAbAgs
STRUCTUREINPUTS = Path.home() / "alphafold_1a14.cif"   # or a directory
ENCDIR = Path.cwd() / "encodings"; TMPDIR = Path.cwd() / "temporary"; OUTDIR = Path.cwd() / "output"
for d in (ENCDIR, TMPDIR, OUTDIR): d.mkdir(exist_ok=True)
data = StructureData()
data.encode_proteins(STRUCTUREINPUTS, ENCDIR, TMPDIR)
EvalAbAgs(data, device="cuda").predict(OUTDIR)
print("Results ->", OUTDIR.resolve())
PY
SB

sbatch run_abepitope.sbatch
```

---

## Troubleshooting & guardrails

- **Stay on the cu121 stack** shown above (PyTorch 2.1.2 + torchvision 0.16.2 + torchaudio 2.1.2 + PyG cu121 wheels). Mixing versions is the #1 cause of import/runtime errors.
- **Don’t upgrade `biotite`** (keep `<0.39`), or ESM-IF1 will break (`filter_backbone`, `PDBxFile`).
- **GPU not found?** You’re probably on a login/CPU node. Use `salloc` (Section 0) or submit a Slurm job (Section 11).
- **HMMER missing?** Load a site module (`module spider HMMER …`) or use the `hmmertools` fallback env and prepend its `bin` to `PATH`.
- **ESM message about “Regression weights not found”** is expected; AbEpiTope inference still runs.
- **Quick output peek**:
  ```bash
  ls -lh output
  head -n 5 output/*
  ```

---

## Credits

- AbEpiTope-1.0: https://github.com/mnielLab/AbEpiTope-1.0  
- ESM-IF1 model weights auto-download to `~/.cache/torch` when `TORCH_HOME` is set.
