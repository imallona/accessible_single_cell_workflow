# pbmc3k workflow

## Aim

1. `download`: fetches `pbmc3k_filtered_gene_bc_matrices.tar.gz` from 10x Genomics into `data/` and extracts it to `data/filtered_gene_bc_matrices/hg19/`.
2. `render_report`: renders `reports/pbmc3k_acc.qmd` with Quarto, writing the report to `reports/` and its downloadable tables, figures, objects, and logs to `results/pbmc3k_acc/`.

Outputs:

- `reports/pbmc3k_acc.html`: the rendered report (source `reports/pbmc3k_acc.qmd`). Its downloadable tables, figures, objects, and logs live in `results/pbmc3k_acc/`, which the report links to with relative paths. Messages and warnings from `Read10X` and `CreateSeuratObject` are shown inline in the report so a screen reader picks them up.
- `logs/download.log` and `logs/render.log`: plain-text progress logs of each rule. Each log ends with `Success` when the rule finished.

## How to run

### Requirements

- `snakemake` and `conda` on your `PATH`.
- The single-cell R packages and Quarto are listed in `envs/single_cell.yaml` (pinned versions) and are installed automatically by snakemake with `--use-conda`.

### Running with snakemake

```sh
# whole pipeline on 1 concurrent task only
snakemake --cores 1 --use-conda

# only the data
snakemake --cores 1 --use-conda data/filtered_gene_bc_matrices/hg19
```

### Accessibility check

The report embeds Quarto's axe accessibility check (`axe: output: document`). It runs in the browser and needs the page served over http, not opened as a local file. Serve it one of these ways, then scroll to the bottom of the page, where axe appends its findings:

```sh
# with the pinned conda environment, via snakemake: re-renders, then serves live
snakemake preview --use-conda

# or with Quarto directly, if quarto is on your PATH
quarto preview reports/pbmc3k_acc.qmd

# or serve the already-built report with any static server, no Quarto needed
python -m http.server   # then open http://localhost:8000/reports/pbmc3k_acc.html
```

## License

MIT, see `LICENSE`.
