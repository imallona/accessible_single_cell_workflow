# Creates a Zenodo deposition for this repository with zen4R and uploads one
# archive file. Publishing is commented out and irreversible; enable it only
# once the metadata and file are confirmed.

## CONFIG: update both values before running.
## zenodo_token needs the deposit:write and deposit:actions scopes.
## Add sandbox = TRUE to ZenodoManager$new() to target sandbox.zenodo.org.
zenodo_token <- "updateme"
archive_path <- "/tmp/updateme.zip"

library(zen4R)

myrec <- ZenodoRecord$new()
myrec$setTitle("An accessible scRNA-seq workflow: adapted PBMC Seurat tutorial")
myrec$setDescription(paste(
  "A worked single-cell RNA-seq workflow built for nonvisual accessibility and",
  "computational reproducibility. It processes the public 10x Genomics PBMC 3k dataset",
  "with Seurat, orchestrated by Snakemake and reported with Quarto. The workflow renders",
  "a screen-reader-friendly report as HTML and as a tagged PDF/UA-1 file (built with Typst,",
  "no LaTeX needed) validated against PDF/UA-1 with veraPDF. Accessibility choices include",
  "named table columns so no header is blank, wrapped rather than horizontally scrolled code",
  "output, high-contrast link colours, no hyphenation, cleaned render logs stripped of ANSI",
  "codes and progress bars, and an opt-in axe accessibility check. This software accompanies",
  "the manuscript on nonvisual, reproducible bioinformatics."))
myrec$addAdditionalDescription(paste(
  "Every diagnostic is preserved as a named, plain-text table a screen reader can read row",
  "by row, so the analytical decisions behind each plot are recorded in text rather than",
  "encoded only in a figure."), type = "abstract")

myrec$setPublicationDate(Sys.Date())
myrec$setResourceType("software")

# Author order follows the manuscript author list (Kientsch, Mallona).
myrec$addCreator(firstname = "Jacqueline", lastname = "Kientsch", orcid = "0009-0008-4253-2140")
myrec$addCreator(firstname = "Izaskun", lastname = "Mallona", orcid = "0000-0002-2853-7526")

myrec$setLicense("mit")
myrec$setSubjects(c(
  "accessibility",
  "screen reader",
  "nonvisual",
  "reproducibility",
  "single-cell RNA-seq",
  "scRNA-seq",
  "Seurat",
  "Snakemake",
  "Quarto",
  "PDF/UA"))
myrec$setPublisher("Zenodo")
myrec$setVersion("0.1.0")

# Source repository this deposit archives.
myrec$addRelatedIdentifier(
  "https://github.com/imallona/kientsch_accessibility_good_practices",
  scheme = "url", relation_type = "isderivedfrom")

zenodo <- ZenodoManager$new(token = zenodo_token, logger = "INFO")

# depositRecord returns the record with its assigned id; later calls need it.
myrec <- zenodo$depositRecord(myrec)

# At least one file is required before a record can be published.
zenodo$uploadFile(archive_path, record = myrec)

# Irreversible once run: a published record cannot be deleted and its files
# cannot be changed. Uncomment when the metadata and file are confirmed correct.
# zenodo$publishRecord(myrec$id)
