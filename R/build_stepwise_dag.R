# Build a compact, publication-ready BET 2026 model-development diagram.

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
  models <- get("stepwise_models", envir = config, inherits = FALSE)
  labels <- setNames(as.character(models$model_label), as.character(models$step_id))

  ids <- c(
    "01-Diag2023", "02a-NewExe1003", "02b-Ini1007", "02c-LengthWeight",
    "03-FixM", "04-NewStructure", "05-ConvertToLength", "06-AddLengthData",
    "07-DataTo2024", "08-RegionalCPUE", "09a-BASE075", "09b-REG075",
    "09c-SUB075", "10-MIX015", "11-TAGF2ON", "12-TimeVaryingCV",
    "13-EffortCreep", "14-CPUESigma", "15-SelectivityUpdate",
    "16a-DOMDiv200", "16b-Francis", "16c-DMG8Nmax25"
  )
  missing <- setdiff(ids, names(labels))
  if (length(missing)) {
    stop("The DAG layout is missing configured labels for: ", paste(missing, collapse = ", "))
  }

  selected_rows <- list(
    c(
      "source", "01-Diag2023", "02a-NewExe1003", "02b-Ini1007",
      "02c-LengthWeight", "03-FixM", "04-NewStructure"
    ),
    c(
      "05-ConvertToLength", "06-AddLengthData", "07-DataTo2024",
      "08-RegionalCPUE", "09c-SUB075", "10-MIX015"
    ),
    c(
      "11-TAGF2ON", "12-TimeVaryingCV", "13-EffortCreep",
      "14-CPUESigma", "15-SelectivityUpdate", "16c-DMG8Nmax25"
    )
  )
  row1_x <- seq(1.15, 15.55, length.out = length(selected_rows[[1L]]))
  row2_x <- rev(seq(1.15, 15.55, length.out = length(selected_rows[[2L]])))
  row3_x <- seq(1.15, 15.55, length.out = length(selected_rows[[3L]]))
  nodes <- rbind(
    data.frame(
      id = selected_rows[[1L]], x = row1_x, y = 7.25,
      category = c("source", rep("carried", 6L))
    ),
    data.frame(
      id = selected_rows[[2L]], x = row2_x, y = 4.85,
      category = "carried"
    ),
    data.frame(
      id = selected_rows[[3L]], x = row3_x, y = 2.45,
      category = c(rep("carried", 5L), "final")
    ),
    data.frame(
      id = c("09a-BASE075", "09b-REG075"),
      x = 5.5, y = c(6.08, 3.62), category = "alternative"
    ),
    data.frame(
      id = c("16a-DOMDiv200", "16b-Francis"),
      x = c(10.7, 13.25), y = 1.05, category = "alternative"
    ),
    stringsAsFactors = FALSE
  )
  nodes$step <- ifelse(nodes$id == "source", "Source", sub("-.*$", "", nodes$id))
  nodes$name <- ifelse(nodes$id == "source", "2023 diagnostic model", labels[nodes$id])
  nodes$display <- vapply(
    seq_len(nrow(nodes)),
    function(i) {
      node_name <- nodes$name[[i]]
      if (identical(nodes$id[[i]], "16c-DMG8Nmax25")) {
        node_name <- "Dirichlet-\nmultinomial"
      }
      wrapped <- paste(strwrap(node_name, width = 16L), collapse = "\n")
      paste(nodes$step[[i]], wrapped, sep = "\n")
    },
    character(1)
  )

  node_lookup <- split(nodes, nodes$id)
  edge_rows <- list()
  add_edge <- function(from, to, kind = "carried", bend = 0) {
    a <- node_lookup[[from]]
    b <- node_lookup[[to]]
    dx <- b$x - a$x
    dy <- b$y - a$y
    distance <- sqrt(dx^2 + dy^2)
    ux <- dx / distance
    uy <- dy / distance
    boundary_distance <- 1 / max(abs(ux) / 0.92, abs(uy) / 0.48)
    edge_offset <- boundary_distance + 0.08
    edge_rows[[length(edge_rows) + 1L]] <<- data.frame(
      x = a$x + edge_offset * ux,
      y = a$y + edge_offset * uy,
      xend = b$x - edge_offset * ux,
      yend = b$y - edge_offset * uy,
      kind = kind,
      bend = bend
    )
  }

  for (selected_row in selected_rows) {
    for (i in seq_len(length(selected_row) - 1L)) {
      add_edge(selected_row[[i]], selected_row[[i + 1L]])
    }
  }
  add_edge("04-NewStructure", "05-ConvertToLength")
  add_edge("10-MIX015", "11-TAGF2ON")
  add_edge("08-RegionalCPUE", "09a-BASE075", "alternative", 0.18)
  add_edge("08-RegionalCPUE", "09b-REG075", "alternative", -0.18)
  add_edge("09a-BASE075", "09c-SUB075", "alternative", -0.18)
  add_edge("09b-REG075", "09c-SUB075", "alternative", 0.18)
  add_edge("15-SelectivityUpdate", "16a-DOMDiv200", "alternative")
  add_edge("16a-DOMDiv200", "16b-Francis", "alternative")
  edges <- do.call(rbind, edge_rows)

  palette <- c(
    source = "#53636D",
    carried = "#176B70",
    alternative = "#B85C18",
    final = "#004D52"
  )
  fills <- c(
    source = "#53636D",
    carried = "#E7F1F0",
    alternative = "#FFF1DF",
    final = "#006B70"
  )
  caption <- paste(
    "BET 2026 model-development pathway. Solid arrows show the selected",
    "sequence; dashed arrows identify alternative age-composition and",
    "length-composition weighting models."
  )

  plot <- ggplot2::ggplot() +
    ggplot2::geom_segment(
      data = edges,
      ggplot2::aes(
        x = x, y = y, xend = xend, yend = yend,
        colour = kind, linetype = kind
      ),
      linewidth = 0.9,
      lineend = "round",
      arrow = grid::arrow(length = grid::unit(2.1, "mm"), type = "closed")
    ) +
    ggplot2::geom_rect(
      data = nodes,
      ggplot2::aes(
        xmin = x - 0.92, xmax = x + 0.92,
        ymin = y - 0.48, ymax = y + 0.48,
        fill = category, colour = category
      ),
      linewidth = 1
    ) +
    ggplot2::geom_text(
      data = nodes,
      ggplot2::aes(
        x = x, y = y, label = display,
        colour = ifelse(category %in% c("source", "final"), "light", "dark")
      ),
      lineheight = 0.93,
      fontface = "bold",
      size = 3.75
    ) +
    ggplot2::annotate(
      "text", x = 0.22, y = c(8.04, 1.62),
      label = c(
        "SELECTED MODEL-DEVELOPMENT PATHWAY",
        "COMPOSITION-WEIGHTING ALTERNATIVES"
      ),
      hjust = 0,
      colour = "#44515A",
      fontface = "bold",
      size = 3.4
    ) +
    ggplot2::scale_fill_manual(values = fills, guide = "none") +
    ggplot2::scale_colour_manual(
      values = c(palette, light = "#FFFFFF", dark = "#183036"),
      guide = "none"
    ) +
    ggplot2::scale_linetype_manual(
      values = c(carried = "solid", alternative = "22"),
      guide = "none"
    ) +
    ggplot2::coord_cartesian(xlim = c(0.05, 16.65), ylim = c(0.35, 8.25), clip = "off") +
    ggplot2::labs(colour = NULL) +
    ggplot2::theme_void(base_family = "sans") +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "#FFFFFF", colour = NA),
      plot.margin = ggplot2::margin(8, 8, 4, 8)
    )

  figure_dir <- file.path(output_dir, "figures")
  dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
  png_path <- file.path(figure_dir, paste0(basename, ".png"))
  ggplot2::ggsave(
    filename = png_path,
    plot = plot,
    device = ragg::agg_png,
    width = 14,
    height = 7,
    units = "in",
    dpi = 300,
    background = "#FFFFFF"
  )

  invisible(list(png = png_path, nodes = nodes, caption = caption))
}

if (sys.nframe() == 0L) {
  build_stepwise_dag()
}
