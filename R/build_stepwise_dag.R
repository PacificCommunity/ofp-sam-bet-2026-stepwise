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
    "16a-DOMDiv200", "16b-Francis", "16c-DMG8Nmax25",
    "17a-F15FormRelaxed", "17b-F22FormRelaxed",
    "17c-F15F22FormRelaxed", "17d-AllSelectivityFormRelaxed"
  )
  missing <- setdiff(ids, names(labels))
  if (length(missing)) {
    stop("The DAG layout is missing configured labels for: ", paste(missing, collapse = ", "))
  }

  row1_ids <- ids[1:8]
  row2_main_ids <- c(
    "07-DataTo2024", "08-RegionalCPUE", "09c-SUB075", "10-MIX015",
    "11-TAGF2ON", "12-TimeVaryingCV", "13-EffortCreep",
    "14-CPUESigma", "15-SelectivityUpdate"
  )
  nodes <- rbind(
    data.frame(id = "source", x = 0.9, y = 8.1, category = "source"),
    data.frame(id = row1_ids, x = seq(2.7, 15.3, length.out = 8L), y = 8.1, category = "carried"),
    data.frame(
      id = row2_main_ids,
      x = c(0.9, 2.7, 6.3, 7.9, 9.5, 11.1, 12.7, 14.3, 15.9),
      y = 4.8,
      category = "carried"
    ),
    data.frame(id = c("09a-BASE075", "09b-REG075"), x = 4.5, y = c(5.75, 3.85), category = "alternative"),
    data.frame(id = c("16a-DOMDiv200", "16b-Francis"), x = c(2.7, 4.5), y = 2.05, category = "alternative"),
    data.frame(id = "16c-DMG8Nmax25", x = 2.7, y = 0.55, category = "final"),
    data.frame(
      id = c(
        "17a-F15FormRelaxed", "17b-F22FormRelaxed",
        "17c-F15F22FormRelaxed", "17d-AllSelectivityFormRelaxed"
      ),
      x = c(8, 10.6, 13.2, 15.8),
      y = 0.55,
      category = "alternative"
    ),
    stringsAsFactors = FALSE
  )
  nodes$step <- ifelse(nodes$id == "source", "Source", sub("-.*$", "", nodes$id))
  nodes$name <- ifelse(nodes$id == "source", "2023 diagnostic model", labels[nodes$id])
  nodes$display <- vapply(
    seq_len(nrow(nodes)),
    function(i) {
      node_name <- nodes$name[[i]]
      if (identical(node_name, "Dirichlet-multinomial")) {
        node_name <- "Dirichlet-\nmultinomial"
      }
      wrapped <- paste(strwrap(node_name, width = 18L), collapse = "\n")
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
    edge_rows[[length(edge_rows) + 1L]] <<- data.frame(
      x = a$x + 0.74 * ux,
      y = a$y + 0.43 * uy,
      xend = b$x - 0.74 * ux,
      yend = b$y - 0.43 * uy,
      kind = kind,
      bend = bend
    )
  }

  row1_chain <- c("source", row1_ids)
  for (i in seq_len(length(row1_chain) - 1L)) {
    add_edge(row1_chain[[i]], row1_chain[[i + 1L]])
  }
  for (i in seq_len(length(row2_main_ids) - 1L)) {
    if (row2_main_ids[[i]] == "08-RegionalCPUE") next
    add_edge(row2_main_ids[[i]], row2_main_ids[[i + 1L]])
  }
  add_edge("08-RegionalCPUE", "09c-SUB075")
  add_edge("08-RegionalCPUE", "09a-BASE075", "alternative", 0.18)
  add_edge("08-RegionalCPUE", "09b-REG075", "alternative", -0.18)
  add_edge("09a-BASE075", "09c-SUB075", "alternative", -0.18)
  add_edge("09b-REG075", "09c-SUB075", "alternative", 0.18)
  add_edge("16a-DOMDiv200", "16b-Francis", "alternative")
  edges <- do.call(rbind, edge_rows)

  wrap_edges <- rbind(
    data.frame(
      group = "row1-row2",
      x = c(16.04, 16.75, 16.75, 0.1, 0.1),
      y = c(8.1, 8.1, 6.65, 6.65, 5.23),
      kind = "carried"
    ),
    data.frame(
      group = "row2-row3-final",
      x = c(16.64, 16.75, 16.75, 1.15, 1.15, 1.96),
      y = c(4.8, 4.8, 2.75, 2.75, 0.55, 0.55),
      kind = "carried"
    )
  )
  alternative_wrap <- data.frame(
    group = "row2-row3-alt",
    x = c(16.64, 16.55, 16.55, 1.15, 1.96),
    y = c(4.8, 4.8, 2.45, 2.45, 2.05),
    kind = "alternative"
  )
  sensitivity_bus <- data.frame(
    x = c(2.7, 2.7, 15.8),
    y = c(0.12, -0.2, -0.2),
    group = "sensitivity-bus"
  )
  sensitivity_branches <- data.frame(
    x = c(8, 10.6, 13.2, 15.8),
    y = -0.2,
    xend = c(8, 10.6, 13.2, 15.8),
    yend = 0.12
  )

  palette <- c(
    source = "#5C6770",
    carried = "#007C78",
    alternative = "#D55E00",
    final = "#005F5B"
  )
  fills <- c(
    source = "#5C6770",
    carried = "#E0F2F1",
    alternative = "#FCE8D2",
    final = "#007C78"
  )
  caption <- "Sequential model development and composition-weighting alternatives."

  plot <- ggplot2::ggplot() +
    ggplot2::geom_path(
      data = wrap_edges,
      ggplot2::aes(x = x, y = y, group = group, colour = kind),
      linewidth = 0.8,
      lineend = "round",
      arrow = grid::arrow(length = grid::unit(2.5, "mm"), type = "closed")
    ) +
    ggplot2::geom_path(
      data = alternative_wrap,
      ggplot2::aes(x = x, y = y, group = group, colour = kind),
      linewidth = 0.7,
      linetype = "22",
      lineend = "round",
      arrow = grid::arrow(length = grid::unit(2.3, "mm"), type = "closed")
    ) +
    ggplot2::geom_segment(
      data = edges,
      ggplot2::aes(
        x = x, y = y, xend = xend, yend = yend,
        colour = kind, linetype = kind
      ),
      linewidth = 0.75,
      lineend = "round",
      arrow = grid::arrow(length = grid::unit(2.3, "mm"), type = "closed")
    ) +
    ggplot2::geom_path(
      data = sensitivity_bus,
      ggplot2::aes(x = x, y = y, group = group),
      colour = palette[["alternative"]],
      linewidth = 0.7,
      linetype = "22",
      lineend = "round"
    ) +
    ggplot2::geom_segment(
      data = sensitivity_branches,
      ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
      colour = palette[["alternative"]],
      linewidth = 0.7,
      linetype = "22",
      arrow = grid::arrow(length = grid::unit(2.3, "mm"), type = "closed")
    ) +
    ggplot2::geom_rect(
      data = nodes,
      ggplot2::aes(
        xmin = x - 0.74, xmax = x + 0.74,
        ymin = y - 0.43, ymax = y + 0.43,
        fill = category, colour = category
      ),
      linewidth = 0.9
    ) +
    ggplot2::geom_text(
      data = nodes,
      ggplot2::aes(
        x = x, y = y, label = display,
        colour = ifelse(category %in% c("source", "final"), "light", "dark")
      ),
      lineheight = 0.95,
      fontface = "bold",
      size = 3.15
    ) +
    ggplot2::annotate(
      "text", x = 0.05, y = c(8.85, 6.35, 2.85),
      label = c("FOUNDATION", "MODEL DEVELOPMENT", "WEIGHTING AND SENSITIVITY"),
      hjust = 0,
      colour = "#44515A",
      fontface = "bold",
      size = 3.2
    ) +
    ggplot2::scale_fill_manual(values = fills, guide = "none") +
    ggplot2::scale_colour_manual(
      values = c(palette, light = "#FFFFFF", dark = "#183036"),
      breaks = c("source", "carried", "alternative", "final"),
      labels = c("Source", "Carried pathway", "Alternative", "Selected final")
    ) +
    ggplot2::scale_linetype_manual(
      values = c(carried = "solid", alternative = "22"),
      guide = "none"
    ) +
    ggplot2::coord_cartesian(xlim = c(-0.05, 16.85), ylim = c(-0.35, 9.05), clip = "off") +
    ggplot2::labs(
      title = "BET 2026 model-development pathway",
      subtitle = "Scientific changes are introduced stepwise; composition-weighting alternatives branch after the selectivity update.",
      colour = NULL
    ) +
    ggplot2::theme_void(base_family = "sans") +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "#FAFAF7", colour = NA),
      plot.title = ggplot2::element_text(size = 18, face = "bold", colour = "#183036"),
      plot.subtitle = ggplot2::element_text(size = 11, colour = "#44515A", margin = ggplot2::margin(b = 8)),
      legend.position = "top",
      legend.justification = "right",
      legend.direction = "horizontal",
      legend.text = ggplot2::element_text(size = 9),
      legend.key.width = grid::unit(7, "mm"),
      plot.margin = ggplot2::margin(10, 18, 10, 10)
    )

  figure_dir <- file.path(output_dir, "figures")
  dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
  png_path <- file.path(figure_dir, paste0(basename, ".png"))
  ggplot2::ggsave(
    filename = png_path,
    plot = plot,
    device = ragg::agg_png,
    width = 16,
    height = 9,
    units = "in",
    dpi = 300,
    background = "#FAFAF7"
  )

  invisible(list(png = png_path, nodes = nodes, caption = caption))
}

if (sys.nframe() == 0L) {
  build_stepwise_dag()
}
