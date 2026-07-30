# Build a publication-ready diagram of the final BET 2026 pathway.

build_stepwise_dag <- function(
    config_path = "job-config.R",
    output_dir = Sys.getenv("OUTPUT_DIR", "outputs"),
    basename = "bet-2026-stepwise-dag") {
  for (package in c("ggplot2", "ragg")) {
    if (!requireNamespace(package, quietly = TRUE)) {
      stop("The ", package, " package is required to build the stepwise diagram.")
    }
  }

  config <- new.env(parent = baseenv())
  sys.source(normalizePath(config_path, mustWork = TRUE), envir = config)
  models <- config$stepwise_models
  models$id <- as.character(models$step_id)
  models$parent <- as.character(models$scientific_parent_id)
  models$label <- as.character(models$model_label)
  models$category <- ifelse(
    models$id == "19-DMG8Nmax25", "final",
    ifelse(as.logical(models$selected), "selected", "alternative")
  )

  expected <- c(
    "01-Diag2023", "02-NewExeIni1007", "03-FixM", "04-LengthWeight",
    "05-NewStructure", "06-ConvertToLength", "07-AddLengthData",
    "08-DataTo2024", "09-SizeDataQC", "10-RegionalCPUE",
    "11-TimeVaryingCV", "12-CPUEErrorCalibration", "13-NewAgeData",
    "14a-REG075", "14b-SUB075", "15-SelectivityUpdate", "16-MIX020",
    "17-TagReportingExclusion", "18-EffortCreep", "19-DMG8Nmax25"
  )
  if (!identical(models$id, expected)) {
    stop("Configured rows do not match the final 20-model pathway.")
  }

  selected <- models[as.logical(models$selected), , drop = FALSE]
  selected$order <- seq_len(nrow(selected))
  selected$column <- pmin(4L, ceiling(selected$order / 5L))
  selected$row <- ave(selected$order, selected$column, FUN = seq_along)
  selected$x <- c(1.5, 4.4, 7.3, 10.2)[selected$column]
  selected$y <- 6.2 - 1.05 * (selected$row - 1L)

  alternative <- models[!as.logical(models$selected), , drop = FALSE]
  alternative$x <- 8.7
  alternative$y <- selected$y[selected$id == "14b-SUB075"]
  nodes <- rbind(selected[, names(models)], alternative[, names(models)])
  xy <- rbind(
    selected[, c("id", "x", "y")],
    alternative[, c("id", "x", "y")]
  )
  nodes$x <- xy$x[match(nodes$id, xy$id)]
  nodes$y <- xy$y[match(nodes$id, xy$id)]
  nodes$step <- sub("-.*$", "", nodes$id)
  nodes$display <- paste0(nodes$step, "  ", nodes$label)

  edges <- data.frame()
  for (i in seq_len(nrow(nodes))) {
    parent <- nodes$parent[[i]]
    if (!parent %in% nodes$id) next
    from <- nodes[nodes$id == parent, , drop = FALSE]
    to <- nodes[i, , drop = FALSE]
    edges <- rbind(edges, data.frame(
      x = from$x + 0.84, y = from$y,
      xend = to$x - 0.84, yend = to$y,
      category = if (to$category == "alternative") "alternative" else "selected"
    ))
  }

  colours <- c(selected = "#23777C", alternative = "#C86616", final = "#123F48")
  fills <- c(selected = "#F7FBFB", alternative = "#FFF6EC", final = "#E9F3F3")
  caption <- paste(
    "BET 2026 final stepwise pathway. Teal arrows show the selected cumulative",
    "sequence; the orange branch is the alternative regional CAAL treatment.",
    "The final node matches the Job 18718 treatment."
  )

  plot <- ggplot2::ggplot() +
    ggplot2::geom_segment(
      data = edges,
      ggplot2::aes(x = x, y = y, xend = xend, yend = yend,
                   colour = category, linetype = category),
      linewidth = 0.75,
      arrow = grid::arrow(length = grid::unit(1.7, "mm"), type = "closed")
    ) +
    ggplot2::geom_label(
      data = nodes,
      ggplot2::aes(x = x, y = y, label = display,
                   colour = category, fill = category),
      size = 2.55, linewidth = 0.55, label.r = grid::unit(0.08, "lines"),
      label.padding = grid::unit(0.22, "lines"),
      fontface = ifelse(nodes$category == "final", "bold", "plain")
    ) +
    ggplot2::annotate(
      "text", x = 0.45, y = 7.1,
      label = "BET 2026 FINAL STEPWISE PATHWAY",
      hjust = 0, colour = "#253E45", fontface = "bold", size = 4.2
    ) +
    ggplot2::annotate(
      "text", x = 0.45, y = 0.55,
      label = caption, hjust = 0, colour = "#5C7075", size = 2.55
    ) +
    ggplot2::scale_colour_manual(values = colours, guide = "none") +
    ggplot2::scale_fill_manual(values = fills, guide = "none") +
    ggplot2::scale_linetype_manual(
      values = c(selected = "solid", alternative = "22"), guide = "none"
    ) +
    ggplot2::coord_cartesian(
      xlim = c(0.3, 11.35), ylim = c(0.35, 7.25), clip = "off"
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
    width = 11.69, height = 7.35, units = "in", dpi = 300,
    background = "white"
  )
  invisible(list(png = png_path, nodes = nodes, caption = caption))
}

if (sys.nframe() == 0L) build_stepwise_dag()
