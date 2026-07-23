# Figure styling for low-vision readers, sourced by pbmc3k_acc.qmd.
# Large fonts, labelled axes, a colourblind-safe palette; scatter and UMAP
# panels square, heatmaps taller than wide. Needs ggplot2, ggrepel, Seurat.

# Okabe-Ito hues with the light yellow swapped for a darker amber and a mid grey
# added, so all nine categories stay high-contrast on white.
accessible_category_palette <- c(
  "#000000",
  "#E69F00",
  "#56B4E9",
  "#009E73",
  "#0072B2",
  "#D55E00",
  "#CC79A7",
  "#997000",
  "#666666"
)

# Single-feature expression ramp. Light grey to dark navy is monotonic in
# lightness, so magnitude reads without relying on hue.
accessible_sequential_colours <- c("grey85", "#08306B")

# Diverging ramp for the heatmaps, symmetric around zero, colourblind safe.
accessible_diverging_colours <- rev(grDevices::hcl.colors(11, "Blue-Red 3"))

accessible_theme <- ggplot2::theme_bw(base_size = 16) +
  ggplot2::theme(
    axis.title = ggplot2::element_text(size = 18, face = "bold"),
    axis.text = ggplot2::element_text(size = 14, colour = "black"),
    plot.title = ggplot2::element_text(size = 18, face = "bold"),
    legend.title = ggplot2::element_text(size = 16, face = "bold"),
    legend.text = ggplot2::element_text(size = 14),
    strip.text = ggplot2::element_text(size = 15, face = "bold"),
    strip.background = ggplot2::element_rect(fill = "grey90", colour = "black"),
    panel.grid.minor = ggplot2::element_blank()
  )

# Apply the shared theme to a plot or patchwork; `&` reaches every panel and a
# lone ggplot. square = TRUE for scatter and UMAP. accessible_theme is complete,
# so it would reset an earlier NoLegend(); suppress the legend here instead.
style_figure <- function(plot, square = FALSE, legend = TRUE) {
  styled <- plot & accessible_theme
  if (!isTRUE(legend)) {
    styled <- styled & ggplot2::theme(legend.position = "none")
  }
  if (isTRUE(square)) {
    styled <- styled & ggplot2::theme(aspect.ratio = 1)
  }
  styled
}

# Larger heatmap labels. A complete theme would draw grid lines over the cells,
# so only text sizes change.
style_heatmap <- function(plot) {
  plot & ggplot2::theme(
    axis.text = ggplot2::element_text(size = 12, colour = "black"),
    axis.text.y = ggplot2::element_text(size = 12, colour = "black"),
    plot.title = ggplot2::element_text(size = 18, face = "bold"),
    legend.title = ggplot2::element_text(size = 15),
    legend.text = ggplot2::element_text(size = 13)
  )
}

# Labelled UMAP for low-vision readers. Each group name sits at its centroid in a
# bold white box with a black border, legible over any point colour, with a
# leader line when repel moves the box off centre.
accessible_labelled_umap <- function(
  object,
  reduction = "umap",
  point_size = 0.6,
  label_size = 5
) {
  embedding <- Seurat::Embeddings(object, reduction = reduction)

  centroids <- data.frame(
    group = as.character(Seurat::Idents(object)),
    axis_1 = embedding[, 1],
    axis_2 = embedding[, 2],
    stringsAsFactors = FALSE
  ) |>
    dplyr::group_by(group) |>
    dplyr::summarise(
      axis_1 = stats::median(axis_1),
      axis_2 = stats::median(axis_2),
      .groups = "drop"
    )

  base_plot <- Seurat::DimPlot(
    object,
    reduction = reduction,
    label = FALSE,
    pt.size = point_size,
    cols = accessible_category_palette
  ) +
    Seurat::NoLegend() +
    ggplot2::xlab("UMAP 1") +
    ggplot2::ylab("UMAP 2")

  base_plot +
    ggrepel::geom_label_repel(
      data = centroids,
      mapping = ggplot2::aes(x = axis_1, y = axis_2, label = group),
      inherit.aes = FALSE,
      size = label_size,
      fontface = "bold",
      colour = "black",
      fill = "white",
      label.size = 0.5,
      box.padding = 0.6,
      min.segment.length = 0,
      segment.colour = "black",
      max.overlaps = Inf,
      seed = 1
    )
}
