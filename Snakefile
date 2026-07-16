import os

configfile: "config.yaml"

DATA_DIR = config["data_dir"]
REPORTS_DIR = config["reports_dir"]
RESULTS_DIR = config["results_dir"]
LOG_DIR = config["log_dir"]
MATRIX_DIR = os.path.join(DATA_DIR, config["matrix_subdir"])
TARBALL = os.path.join(DATA_DIR, "pbmc3k_filtered_gene_bc_matrices.tar.gz")
QMD = config["qmd"]
REPORT_NAME = config["report_name"]
# next to the qmd so the report's relative download links resolve
REPORT_HTML = os.path.join(REPORTS_DIR, REPORT_NAME + ".html")
REPORT_PDF = os.path.join(REPORTS_DIR, REPORT_NAME + ".pdf")
ANALYSIS_DIR = os.path.join(RESULTS_DIR, REPORT_NAME)
# relative to the qmd's folder (quarto's working dir) so download links resolve
ANALYSIS_DIR_REL = os.path.relpath(ANALYSIS_DIR, start=REPORTS_DIR)
# render_pdf depends on this so veraPDF validates the pdf during the build
VERAPDF_MARKER = os.path.join(LOG_DIR, ".verapdf_installed")

# default builds html; pdf is opt-in (snakemake reports/pbmc3k_acc.pdf)
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
    """Installs veraPDF so render_pdf validates the pdf."""
    output:
        marker = touch(VERAPDF_MARKER)
    conda:
        "envs/single_cell.yaml"
    shell:
        "quarto install verapdf --no-prompt"

rule render_html:
    """Renders the vignette to html."""
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
    """Renders the vignette to a tagged pdf with typst. Runs after render_html
    (html as input) so both never write results/ at once (race at --cores>1)."""
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
        quarto preview {input.qmd} --metadata-file reports/axe.yml \
            -P data_dir:$(pwd)/{input.matrix_dir} \
            -P output_dir:{params.analysis_dir_rel} 2>&1 \
            | sh scripts/clean_log.sh
        """
