# Changelog

## Unreleased

- Added a PDF report, `reports/pbmc3k_acc.pdf`, rendered with Quarto's bundled Typst and tagged PDF/UA-1 (`pdf-standard: ua-1`). No LaTeX needed. veraPDF validates it as compliant.
- The default `snakemake` builds the html report. The pdf is opt-in: `snakemake reports/pbmc3k_acc.pdf`.
- Split rendering into `render_html` and `render_pdf`. `render_pdf` takes the html as input and runs after it, so the two never write `results/` at the same time.
- Added `install_verapdf`. `render_pdf` validates the pdf against PDF/UA-1 while it builds.
- PDF download links show as plain file paths; the html keeps clickable links.
- Wide tables, 8 or more columns, render on their own landscape pages in the pdf.
- Added `scripts/clean_log.sh`. It strips colour codes and progress bars from the render and preview output, keeping the chunk counters, messages, and warnings. The render rules write the cleaned stream to both the console and the log file.
