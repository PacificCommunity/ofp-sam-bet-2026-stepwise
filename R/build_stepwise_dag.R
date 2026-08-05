# Build a publication-ready diagram from the models selected at report runtime.

stepwise_dag_value <- function(x, name, default = "") {
  if (!name %in% names(x)) return(rep(default, nrow(x)))
  value <- x[[name]]
  value[is.na(value)] <- default
  value
}

build_stepwise_dag <- function(
    config_path = "job-config.R",
    output_dir = Sys.getenv("OUTPUT_DIR", "outputs"),
    basename = "bet-2026-stepwise-dag",
    models = NULL) {
  for (package in c("ggplot2", "ragg")) {
    if (!requireNamespace(package, quietly = TRUE)) {
      stop("The ", package, " package is required to build the stepwise diagram.")
    }
  }

  if (is.null(models)) {
    config <- new.env(parent = baseenv())
    sys.source(normalizePath(config_path, mustWork = TRUE), envir = config)
    models <- config$stepwise_models
  }
  if (!is.data.frame(models) || !nrow(models) || !"step_id" %in% names(models)) {
    stop("models must be a non-empty data frame with a step_id column.", call. = FALSE)
  }

  models$id <- as.character(models$step_id)
  models$parent <- as.character(stepwise_dag_value(models, "scientific_parent_id"))
  models$label <- as.character(stepwise_dag_value(models, "model_label", models$id))
  selected <- as.logical(stepwise_dag_value(models, "selected", TRUE))
  selected[is.na(selected)] <- TRUE
  models$category <- ifelse(selected, "selected", "alternative")
  models$category[[nrow(models)]] <- "final"

  # Lay out every evaluated configuration in a single chronological timeline.
  # The compact row height is sized for an A4 portrait page, with a concise
  # model title and one-line explanation beside every bold step number.
  nodes <- models
  nodes$order <- seq_len(nrow(nodes))
  nodes$x <- 0.55
  nodes$y <- rev(seq_len(nrow(nodes)))
  nodes$step <- sub("-.*$", "", nodes$id)
  short_titles <- c(
    "01-Diag2023" = "Baseline refit",
    "02-NewExeIni1007" = "Executable and INI",
    "03-FixM" = "Natural mortality",
    "04-LengthWeight" = "Length-weight",
    "05-NewStructure" = "Spatial structure",
    "06-ConvertToLength" = "Weight-to-length data",
    "07-AddLengthData" = "Observed lengths",
    "08-DataTo2024" = "2024 data update",
    "09-SizeDataQC" = "Size-data QC",
    "10-RegionalCPUE" = "Regional CPUE",
    "11-TimeVaryingCV" = "CPUE uncertainty",
    "12-CPUEErrorCalibration" = "CPUE error SDs",
    "13-NewAgeData" = "New CAAL data",
    "14a-REG075" = "Regional CAAL weights",
    "14b-SUB075" = "Sub-basin CAAL weights",
    "15-SelectivityUpdate" = "Selectivity",
    "16-MIX020" = "Tag mixing",
    "17-TagReportingExclusion" = "Tag reporting",
    "18-EffortCreep" = "Effort creep",
    "19-DMG8Nmax25" = "Composition weighting",
    "20-Tau2Fixed" = "Tag overdispersion",
    "21-F33WeakPenalty" = "F33 selectivity penalty",
    "22-Diagnostic" = "Diagnostic model"
  )
  short_descriptions <- c(
    "01-Diag2023" = "Refit the 2023 diagnostic configuration as the starting model.",
    "02-NewExeIni1007" = "Update the MFCL executable and adopt INI format 1007.",
    "03-FixM" = "Fix the Lorenzen natural-mortality scaling parameter.",
    "04-LengthWeight" = "Update the bias-corrected BET length-weight parameters.",
    "05-NewStructure" = "Adopt five regions and 33 fisheries; remap reporting rates.",
    "06-ConvertToLength" = "Convert reweighted weight compositions to length.",
    "07-AddLengthData" = "Add observed lengths where coverage exceeds weight samples.",
    "08-DataTo2024" = "Extend frequency and tagging data through 2024, except CAAL.",
    "09-SizeDataQC" = "Apply PH/ID and domestic mixed-gear size-data rules.",
    "10-RegionalCPUE" = "Introduce regional CPUE indices and abundance scaling.",
    "11-TimeVaryingCV" = "Allow CPUE observation uncertainty to vary through time.",
    "12-CPUEErrorCalibration" = "Fix the five regional CPUE observation-error SDs.",
    "13-NewAgeData" = "Add the new CAAL data with weight 0.75.",
    "14a-REG075" = "Evaluate CAAL reweighting across all five regions.",
    "14b-SUB075" = "Retain sub-basin CAAL reweighting for Regions 3 and 4.",
    "15-SelectivityUpdate" = "Update fishery selectivity and add the weak F10 penalty.",
    "16-MIX020" = "Set release-group tag mixing periods using K = 0.20.",
    "17-TagReportingExclusion" = "Exclude reporting rates during pre-mixing periods.",
    "18-EffortCreep" = "Apply effort-creep adjustments to the regional CPUE indices.",
    "19-DMG8Nmax25" = "Apply Dirichlet-multinomial weighting (G8; Nmax = 25).",
    "20-Tau2Fixed" = "Fix negative-binomial tag overdispersion at tau = 2.",
    "21-F33WeakPenalty" = "Stabilize the data-limited F33 tail without forcing asymptotic selectivity.",
    "22-Diagnostic" = "Fix steepness at h = 0.90 and adopt the Diagnostic model."
  )
  nodes$short_title <- unname(short_titles[nodes$id])
  missing_title <- is.na(nodes$short_title) | !nzchar(nodes$short_title)
  nodes$short_title[missing_title] <- nodes$label[missing_title]
  nodes$description <- unname(short_descriptions[nodes$id])
  missing_description <- is.na(nodes$description) | !nzchar(nodes$description)
  nodes$description[missing_description] <- as.character(
    stepwise_dag_value(nodes[missing_description, , drop = FALSE], "change_axis")
  )

  edges <- data.frame()
  if (nrow(nodes) > 1L) {
    for (i in seq_len(nrow(nodes) - 1L)) {
      from <- nodes[i, , drop = FALSE]
      to <- nodes[i + 1L, , drop = FALSE]
      edges <- rbind(edges, data.frame(
        x = 0.55, y = from$y - 0.24,
        xend = 0.55, yend = to$y + 0.24
      ))
    }
  }

  caption <- paste(
    "Configurations are arranged from top to bottom in evaluation order.",
    "Steps 14a and 14b are shown consecutively, and the final row is the Diagnostic model."
  )

  plot <- ggplot2::ggplot() +
    ggplot2::geom_rect(
      data = nodes[nodes$order %% 2L == 0L & nodes$category != "final", , drop = FALSE],
      ggplot2::aes(ymin = y - 0.42, ymax = y + 0.42),
      xmin = 0.05, xmax = 7.75, fill = "#F4F8F8", colour = NA
    ) +
    ggplot2::geom_rect(
      data = nodes[nodes$category == "final", , drop = FALSE],
      ggplot2::aes(ymin = y - 0.42, ymax = y + 0.42),
      xmin = 0.05, xmax = 7.75, fill = "#123F48", colour = NA
    ) +
    ggplot2::geom_segment(
      data = edges,
      ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
      colour = "#1F6F78", linewidth = 0.62,
      arrow = grid::arrow(length = grid::unit(1.35, "mm"), type = "closed")
    ) +
    ggplot2::geom_label(
      data = nodes,
      ggplot2::aes(x = x, y = y, label = step),
      colour = "#174C55", fill = "#FFFFFF", linewidth = 0.55,
      size = 2.45, fontface = "bold",
      label.r = grid::unit(0.12, "lines"),
      label.padding = grid::unit(0.16, "lines")
    ) +
    ggplot2::geom_text(
      data = nodes[nodes$category != "final", , drop = FALSE],
      ggplot2::aes(x = 1.05, y = y, label = short_title),
      hjust = 0, colour = "#173F48", size = 2.55,
      fontface = "bold"
    ) +
    ggplot2::geom_text(
      data = nodes[nodes$category != "final", , drop = FALSE],
      ggplot2::aes(x = 3.05, y = y, label = description),
      hjust = 0, colour = "#516B73", size = 2.10
    ) +
    ggplot2::geom_text(
      data = nodes[nodes$category == "final", , drop = FALSE],
      ggplot2::aes(x = 1.05, y = y, label = short_title),
      hjust = 0, colour = "#FFFFFF", size = 2.55, fontface = "bold"
    ) +
    ggplot2::geom_text(
      data = nodes[nodes$category == "final", , drop = FALSE],
      ggplot2::aes(x = 3.05, y = y, label = description),
      hjust = 0, colour = "#DCEDEF", size = 2.10
    ) +
    ggplot2::annotate(
      "text", x = 0.55, y = nrow(nodes) + 1.05, label = "STEP",
      colour = "#60757B", size = 2.2, fontface = "bold"
    ) +
    ggplot2::annotate(
      "text", x = 1.05, y = nrow(nodes) + 1.05, label = "MODEL CHANGE",
      hjust = 0, colour = "#60757B", size = 2.2, fontface = "bold"
    ) +
    ggplot2::annotate(
      "text", x = 3.05, y = nrow(nodes) + 1.05, label = "WHAT CHANGED",
      hjust = 0, colour = "#60757B", size = 2.2, fontface = "bold"
    ) +
    ggplot2::annotate(
      "segment", x = 0.05, xend = 7.75,
      y = nrow(nodes) + 0.63, yend = nrow(nodes) + 0.63,
      colour = "#9CB2B8", linewidth = 0.55
    ) +
    ggplot2::coord_cartesian(
      xlim = c(0, 7.8), ylim = c(0.48, nrow(nodes) + 1.38), clip = "off"
    ) +
    ggplot2::theme_void(base_family = "sans") +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "white", colour = NA),
      plot.margin = ggplot2::margin(4, 4, 4, 4)
    )

  figure_dir <- file.path(output_dir, "figures")
  dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
  png_path <- file.path(figure_dir, paste0(basename, ".png"))
  ggplot2::ggsave(
    png_path, plot, device = ragg::agg_png,
    width = 7.15, height = 9.25, units = "in", dpi = 300,
    background = "white"
  )
  pdf_path <- file.path(figure_dir, paste0(basename, ".pdf"))
  ggplot2::ggsave(
    pdf_path, plot, device = grDevices::cairo_pdf,
    width = 7.15, height = 9.25, units = "in", bg = "white"
  )
  invisible(list(png = png_path, pdf = pdf_path, nodes = nodes, edges = edges, caption = caption))
}

if (sys.nframe() == 0L) build_stepwise_dag()
