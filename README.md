# pbmc3k workflow

## Aim

1. `download`: fetches `pbmc3k_filtered_gene_bc_matrices.tar.gz` from 10x Genomics into `data/` and extracts it to `data/filtered_gene_bc_matrices/hg19/`.
2. `render_report`: renders `reports/pbmc3k.qmd` with Quarto, writing the knitted output to `results/`.

Outputs:

- `results/pbmc3k.html`: the rendered report (source `.qmd` lives in `reports/`). Messages and warnings from `Read10X` and `CreateSeuratObject` are shown inline in the report so a screen reader picks them up.
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

# only the report
snakemake --cores 1 --use-conda results/pbmc3k.html
```

### Running with make

The Makefile wraps the same snakemake calls, passing `--cores $(CORES)` and
`--use-conda`. `CORES` defaults to 1.

```sh
make all                  # run the whole pipeline on 1 core
make all CORES=4          # run on 4 cores
make download_data        # only download and extract the data
make render               # only render the report
make clean                # remove data/, results/, logs/, .snakemake/
```

## License

MIT, see `LICENSE`.
