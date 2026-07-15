import os

# the path to the yaml containing the PBMC3k data URL and other configs,
#  such as output paths
configfile: "config.yaml"

DATA_DIR = config["data_dir"]
REPORTS_DIR = config["reports_dir"]
RESULTS_DIR = config["results_dir"]
LOG_DIR = config["log_dir"]
MATRIX_DIR = os.path.join(DATA_DIR, config["matrix_subdir"])
TARBALL = os.path.join(DATA_DIR, "pbmc3k_filtered_gene_bc_matrices.tar.gz")
QMD = config["qmd"]
REPORT_NAME = config["report_name"]
# the report renders in place next to the qmd so its relative download links resolve
REPORT_HTML = os.path.join(REPORTS_DIR, REPORT_NAME + ".html")
# where the vignette writes its tables, figures, objects and per-step logs
ANALYSIS_DIR = os.path.join(RESULTS_DIR, REPORT_NAME)
# quarto runs the qmd with its own folder as the working directory, so output_dir
# must be relative to that folder for the report's download links to resolve
ANALYSIS_DIR_REL = os.path.relpath(ANALYSIS_DIR, start=REPORTS_DIR)

rule all:
    input:
        REPORT_HTML

rule download:
    """Downloads the PBMC3K data"""
    output:
        tarball = TARBALL,
        matrix = directory(MATRIX_DIR)
    params:
        url = config["url"],
        data_dir = DATA_DIR
    log:
        os.path.join(LOG_DIR, "download.log")
    shell:
        """
        {{
          echo "Downloading {params.url}"
          curl -fsSL -o {output.tarball} {params.url}
          echo "Extracting {output.tarball}"
          tar -xzf {output.tarball} -C {params.data_dir}
          echo "Success"
        }} > {log} 2>&1
        """

rule render_report:
    """Renders the accessible PBMC3k Seurat vignette via quarto"""
    input:
        qmd = QMD,
        matrix_dir = MATRIX_DIR
    output:
        html = REPORT_HTML
    params:
        analysis_dir_rel = ANALYSIS_DIR_REL
    log:
        os.path.join(LOG_DIR, "render.log")
    conda:
        "envs/single_cell.yaml"
    shell:
        """
        echo "Rendering {input.qmd}" > {log}
        NO_COLOR=1 quarto render {input.qmd} \
            -P data_dir:$(pwd)/{input.matrix_dir} \
            -P output_dir:{params.analysis_dir_rel} 2>&1 \
            | sed -r 's/\\x1b\\[[0-9;]*m//g' >> {log}
        echo "Success" >> {log}
        """

rule preview:
    """Serve the report with a live browser preview so the axe accessibility check
    runs. Run with: snakemake preview --use-conda"""
    input:
        qmd = QMD,
        matrix_dir = MATRIX_DIR
    params:
        analysis_dir_rel = ANALYSIS_DIR_REL
    conda:
        "envs/single_cell.yaml"
    shell:
        """
        quarto preview {input.qmd} \
            -P data_dir:$(pwd)/{input.matrix_dir} \
            -P output_dir:{params.analysis_dir_rel}
        """
