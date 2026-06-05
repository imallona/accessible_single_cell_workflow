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

rule all:
    input:
        os.path.join(RESULTS_DIR, "pbmc3k.html")

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
    """Renders the PBMC report via quarto"""
    input:
        qmd = os.path.join(REPORTS_DIR, "pbmc3k.qmd"),
        matrix_dir = MATRIX_DIR
    output:
        html = os.path.join(RESULTS_DIR, "pbmc3k.html")
    params:
        results_dir = RESULTS_DIR,
        reports_dir = REPORTS_DIR
    log:
        os.path.join(LOG_DIR, "render.log")
    conda:
        "envs/single_cell.yaml"
    shell:
        """
        echo "Rendering {input.qmd}" > {log}
        NO_COLOR=1 quarto render {input.qmd} \
            --output-dir $(pwd)/{params.results_dir} \
            -P matrix_dir:$(pwd)/{input.matrix_dir} 2>&1 \
            | sed -r 's/\\x1b\\[[0-9;]*m//g' >> {log}
        rm -rf {params.reports_dir}/pbmc3k_files
        echo "Success" >> {log}
        """
