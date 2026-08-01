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

  main <- models[selected, , drop = FALSE]
  main$order <- seq_len(nrow(main))
  rows_per_column <- max(1L, ceiling(nrow(main) / 4L))
  main$column <- ceiling(main$order / rows_per_column)
  main$row <- ave(main$order, main$column, FUN = seq_along)
  main$x <- 1.45 + (main$column - 1L) * 2.9
  main$y <- 6.15 - (main$row - 1L) * 1.02

  alternative <- models[!selected, , drop = FALSE]
  if (nrow(alternative)) {
    parent_x <- main$x[match(alternative$parent, main$id)]
    parent_y <- main$y[match(alternative$parent, main$id)]
    parent_x[is.na(parent_x)] <- max(main$x, na.rm = TRUE) - 1.45
    parent_y[is.na(parent_y)] <- 2.1
    alternative$x <- pmin(parent_x + 2.05, 10.25)
    alternative$y <- parent_y - seq_len(nrow(alternative)) * 0.43
  }
  nodes <- rbind(main[, names(models), drop = FALSE], alternative[, names(models), drop = FALSE])
  xy <- rbind(
    main[, c("id", "x", "y"), drop = FALSE],
    alternative[, c("id", "x", "y"), drop = FALSE]
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
    same_column <- abs(from$x - to$x) < 0.05
    edges <- rbind(edges, data.frame(
      x = if (same_column) from$x else from$x + 0.82,
      y = if (same_column) from$y - 0.12 else from$y,
      xend = if (same_column) to$x else to$x - 0.82,
      yend = if (same_column) to$y + 0.12 else to$y,
      category = if (to$category == "alternative") "alternative" else "selected"
    ))
  }

  colours <- c(selected = "#23777C", alternative = "#C86616", final = "#123F48")
  fills <- c(selected = "#F7FBFB", alternative = "#FFF6EC", final = "#E9F3F3")
  caption <- paste(
    "Stepwise pathway generated from the models supplied to this report.",
    "Teal arrows show the selected cumulative sequence; orange arrows show",
    "comparison branches, and the dark-teal node is the last selected model."
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
      size = 2.45, linewidth = 0.55, label.r = grid::unit(0.08, "lines"),
      label.padding = grid::unit(0.22, "lines"),
      fontface = ifelse(nodes$category == "final", "bold", "plain")
    ) +
    ggplot2::annotate(
      "text", x = 0.35, y = 7.05,
      label = "BET 2026 STEPWISE DEVELOPMENT PATHWAY",
      hjust = 0, colour = "#253E45", fontface = "bold", size = 4.2
    ) +
    ggplot2::annotate(
      "text", x = 0.35, y = 0.42,
      label = caption, hjust = 0, colour = "#5C7075", size = 2.45
    ) +
    ggplot2::scale_colour_manual(values = colours, guide = "none") +
    ggplot2::scale_fill_manual(values = fills, guide = "none") +
    ggplot2::scale_linetype_manual(
      values = c(selected = "solid", alternative = "22"), guide = "none"
    ) +
    ggplot2::coord_cartesian(
      xlim = c(0.2, 11.25), ylim = c(0.25, 7.2), clip = "off"
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
