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
# html and pdf are built by two separate rules. The html keeps the live axe
# check; the pdf is the portable form for submission and Zenodo.
REPORT_PDF = os.path.join(REPORTS_DIR, REPORT_NAME + ".pdf")
# where the vignette writes its tables, figures, objects and per-step logs
ANALYSIS_DIR = os.path.join(RESULTS_DIR, REPORT_NAME)
# quarto runs the qmd with its own folder as the working directory, so output_dir
# must be relative to that folder for the report's download links to resolve
ANALYSIS_DIR_REL = os.path.relpath(ANALYSIS_DIR, start=REPORTS_DIR)
# marker that veraPDF is installed; render_pdf depends on it so quarto validates
# the pdf against its pdf-standard during the build
VERAPDF_MARKER = os.path.join(LOG_DIR, ".verapdf_installed")

# the default build is the html report. The pdf is opt-in: build it with
# snakemake reports/pbmc3k_acc.pdf
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

rule install_verapdf:
    """Installs veraPDF so render_pdf validates the pdf against its pdf-standard."""
    output:
        marker = touch(VERAPDF_MARKER)
    conda:
        "envs/single_cell.yaml"
    shell:
        "quarto install verapdf --no-prompt"

rule render_html:
    """Renders the vignette to html. It links to the tables it writes under
    results/."""
    input:
        qmd = QMD,
        matrix_dir = MATRIX_DIR
    output:
        html = REPORT_HTML
    params:
        analysis_dir_rel = ANALYSIS_DIR_REL
    log:
        os.path.join(LOG_DIR, "render_html.log")
    conda:
        "envs/single_cell.yaml"
    shell:
        """
        echo "Rendering {input.qmd} to html" | tee {log}
        NO_COLOR=1 quarto render {input.qmd} --to html \
            -P data_dir:$(pwd)/{input.matrix_dir} \
            -P output_dir:{params.analysis_dir_rel} 2>&1 \
            | sh scripts/clean_log.sh | tee -a {log}
        rc=${{PIPESTATUS[0]}}
        [ "$rc" -eq 0 ] || {{ echo "render failed (exit $rc)" | tee -a {log}; exit "$rc"; }}
        echo "Success" | tee -a {log}
        """

rule render_pdf:
    """Renders the vignette to a tagged pdf with typst (no LaTeX). Takes the html
    as input to run after render_html, so the two never write results/ at once (a
    race under --cores 2 or more). veraPDF validates the pdf against pdf-standard."""
    input:
        qmd = QMD,
        matrix_dir = MATRIX_DIR,
        html = REPORT_HTML,
        verapdf = VERAPDF_MARKER
    output:
        pdf = REPORT_PDF
    params:
        analysis_dir_rel = ANALYSIS_DIR_REL
    log:
        os.path.join(LOG_DIR, "render_pdf.log")
    conda:
        "envs/single_cell.yaml"
    shell:
        """
        echo "Rendering {input.qmd} to pdf" | tee {log}
        NO_COLOR=1 quarto render {input.qmd} --to typst \
            -P data_dir:$(pwd)/{input.matrix_dir} \
            -P output_dir:{params.analysis_dir_rel} 2>&1 \
            | sh scripts/clean_log.sh | tee -a {log}
        rc=${{PIPESTATUS[0]}}
        [ "$rc" -eq 0 ] || {{ echo "render failed (exit $rc)" | tee -a {log}; exit "$rc"; }}
        echo "Success" | tee -a {log}
        """

rule preview:
    """Live preview server for the browser axe check. Run: snakemake preview --use-conda"""
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
            -P output_dir:{params.analysis_dir_rel} 2>&1 \
            | sh scripts/clean_log.sh
        """
