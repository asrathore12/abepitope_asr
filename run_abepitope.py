from pathlib import Path
from abepitope.main import StructureData, EvalAbAgs

structure_file = Path("/path/to/your/file.pdb")
workdir = Path.cwd()
encdir, tmpdir, outdir = workdir/"encodings", workdir/"temporary", workdir/"output"
for d in (encdir, tmpdir, outdir): d.mkdir(exist_ok=True)

data = StructureData()
data.encode_proteins(structure_file, encdir, tmpdir)

evaluator = EvalAbAgs(data, device="cuda")
evaluator.predict(outdir)

print("Results written to:", outdir)
