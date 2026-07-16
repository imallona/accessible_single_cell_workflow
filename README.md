# pbmc3k workflow

## Aim

1. `download`: fetches `pbmc3k_filtered_gene_bc_matrices.tar.gz` from 10x Genomics into `data/` and extracts it to `data/filtered_gene_bc_matrices/hg19/`.
2. `render_html` and `render_pdf`: render `reports/pbmc3k_acc.qmd` with Quarto to html and to a tagged pdf, writing the reports to `reports/` and the downloadable tables, figures, objects, and logs to `results/pbmc3k_acc/`.

Outputs:

- `reports/pbmc3k_acc.html`: the rendered report (source `reports/pbmc3k_acc.qmd`). Its downloadable tables, figures, objects, and logs live in `results/pbmc3k_acc/`, which the report links to with relative paths. Messages and warnings from `Read10X` and `CreateSeuratObject` are shown inline in the report so a screen reader picks them up.
- `reports/pbmc3k_acc.pdf`: the same report as a tagged PDF/UA-1 file, rendered with Quarto's bundled Typst, so no LaTeX is needed. `pdf-standard: ua-1` in the qmd turns on tagging. The `install_verapdf` rule adds veraPDF, so `render_pdf` validates the file against PDF/UA-1 as it builds. Wide tables sit on their own landscape pages so their columns fit. Download links show as plain file paths, because a file link works only in the html next to its data.
- `logs/download.log`, `logs/render_html.log`, and `logs/render_pdf.log`: plain-text progress logs of each rule. Each log ends with `Success` when the rule finished.

## How to run

### Requirements

- `snakemake` and `conda` on your `PATH`.
- The single-cell R packages and Quarto are listed in `envs/single_cell.yaml` (pinned versions) and are installed automatically by snakemake with `--use-conda`.

### Running with snakemake

```sh
# the html report, the default target
snakemake --cores 1 --use-conda

# the pdf report (tagged PDF/UA-1, built with Typst); builds the html first
snakemake --cores 1 --use-conda reports/pbmc3k_acc.pdf

# only the data
snakemake --cores 1 --use-conda data/filtered_gene_bc_matrices/hg19
```

The default build is the html report; the pdf is opt-in. The pdf rule reruns the analysis and rewrites the same tables under `results/` as the html rule, so it takes the html report as an input and runs after it. That keeps the two from writing `results/` at the same time under `--cores 2` or more.

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

### Accessibility tweaks

Some style choices in this report are there for accessibility.

- Link colour. `reports/custom.scss` sets links to a dark blue (about 7:1 on white), high contrast.
- Wrapped output. Long code output and messages are wrapped instead of put in a horizontal scroll boxes. A scroll box needs a mouse to reach, and a screen reader gives no sign that content continues off-screen.
- Named table columns. The tables carry the row identifier, a cell or a gene, in a named column. A data frame printed with row names leaves the first header blank, which a screen reader reads as an unlabelled column.
- Long tables are avoided.
- Clean render logs. `scripts/clean_log.sh` strips ANSI colour codes and the carriage-return progress bars that redraw in place, keeping the chunk counters, messages, and warnings. The render rules `tee` the cleaned stream to both the console and the log file, and `snakemake preview` streams it live. The bars are the repeated asterisks and equals signs that clutter a log read by a screen reader.

## License

MIT, see `LICENSE`.
