## number of concurrent tasks
CORES ?= 1

SNAKEMAKE = snakemake --cores $(CORES) --use-conda

DATA_DIR = data
REPORTS_DIR = reports
RESULTS_DIR = results
LOG_DIR = logs
MATRIX_DIR = $(DATA_DIR)/filtered_gene_bc_matrices/hg19

.PHONY: all download_data render clean

all:
	$(SNAKEMAKE)

download_data:
	$(SNAKEMAKE) $(MATRIX_DIR)

render:
	$(SNAKEMAKE) $(RESULTS_DIR)/pbmc3k.html

clean:
	rm -rf $(DATA_DIR) $(RESULTS_DIR) $(LOG_DIR) .snakemake
