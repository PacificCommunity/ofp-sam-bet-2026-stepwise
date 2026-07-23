# Build a publication-ready BET 2026 model-development pathway.

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
  configured_ids <- as.character(models$step_id)

  selected_path <- c(
    "01-Diag2023", "02-NewExe1003", "03-Ini1007", "04-FixM",
    "05-LengthWeight", "06-NewStructure", "07-ConvertToLength",
    "08-AddLengthData", "09-TailCompression1Pct", "10-DataTo2024",
    "11-RegionalCPUE", "12-TimeVaryingCV", "13-CPUEErrorCalibration",
    "14-NewAgeData", "15b-SUB075", "16-SelectivityUpdate",
    "17-MIX015", "18-TagReportingExclusion", "19-EffortCreep",
    "20c-DMG8Nmax25"
  )
  comparison_ids <- c("15a-REG075", "20a-DOMDiv200", "20b-Francis")
  missing <- setdiff(c(selected_path, comparison_ids), configured_ids)
  if (length(missing)) {
    stop("The DAG layout is missing configured rows for: ", paste(missing, collapse = ", "))
  }

  nodes <- rbind(
    data.frame(
      id = selected_path[1:5],
      x = 1.45, y = c(5.65, 4.55, 3.45, 2.35, 1.25),
      half_w = 1.00, half_h = 0.27, category = "carried"
    ),
    data.frame(
      id = selected_path[6:10],
      x = 4.00, y = c(1.25, 2.35, 3.45, 4.55, 5.65),
      half_w = 1.00, half_h = 0.27, category = "carried"
    ),
    data.frame(
      id = selected_path[11:14],
      x = 6.90, y = c(5.65, 4.75, 3.85, 2.95),
      half_w = 1.25, half_h = 0.27, category = "carried"
    ),
    data.frame(
      id = c("15b-SUB075", "15a-REG075"),
      x = c(6.15, 7.65), y = 1.85,
      half_w = 0.70, half_h = 0.40,
      category = c("selected", "alternative")
    ),
    data.frame(
      id = "16-SelectivityUpdate",
      x = 6.90, y = 0.80,
      half_w = 1.25, half_h = 0.27, category = "carried"
    ),
    data.frame(
      id = selected_path[17:19],
      x = 10.02, y = c(0.80, 2.00, 3.20),
      half_w = 1.18, half_h = 0.27, category = "carried"
    ),
    data.frame(
      id = c("20c-DMG8Nmax25", "20a-DOMDiv200", "20b-Francis"),
      x = c(10.02, 9.22, 10.82), y = c(5.48, 4.35, 4.35),
      half_w = c(0.92, 0.65, 0.65), half_h = 0.40,
      category = c("final", "alternative", "alternative")
    ),
    stringsAsFactors = FALSE
  )
  nodes$step <- sub("-.*$", "", nodes$id)
  short_names <- c(
    "01-Diag2023" = "2023 diagnostic\nrerun",
    "02-NewExe1003" = "Updated\nexecutable",
    "03-Ini1007" = "Updated INI\nformat",
    "04-FixM" = "Lorenzen M\nscaling fixed",
    "05-LengthWeight" = "Length-weight\nupdate",
    "06-NewStructure" = "Five-region\nstructure",
    "07-ConvertToLength" = "Weight-as-length\nLF input",
    "08-AddLengthData" = "Observed-length\nsupplementation",
    "09-TailCompression1Pct" = "1% LF tail\ncompression",
    "10-DataTo2024" = "Data through\n2024",
    "11-RegionalCPUE" = "Regional CPUE",
    "12-TimeVaryingCV" = "Time-varying CPUE\nuncertainty",
    "13-CPUEErrorCalibration" = "CPUE observation-error\ncalibration",
    "14-NewAgeData" = "New age-at-length\ndata (weight 0.75)",
    "15a-REG075" = "Regional age\nweighting",
    "15b-SUB075" = "Sub-basin age\nweighting",
    "16-SelectivityUpdate" = "Revised fishery-specific\nselectivity",
    "17-MIX015" = "Release-group tag\nmixing periods",
    "18-TagReportingExclusion" = "Reporting rates omitted\nin pre-mixing window",
    "19-EffortCreep" = "Effort creep",
    "20a-DOMDiv200" = "Three domestic\nfisheries\ndownweighted",
    "20b-Francis" = "Francis\nreweighting",
    "20c-DMG8Nmax25" = "Dirichlet-multinomial\nweighting"
  )
  nodes$name <- unname(short_names[nodes$id])
  nodes$status <- ifelse(
    nodes$category == "alternative", "COMPARISON",
    ifelse(
      nodes$category == "selected", "SELECTED",
      ifelse(nodes$category == "final", "SELECTED FINAL", "")
    )
  )
  nodes$branch <- nzchar(nodes$status)
  nodes$step_band <- ifelse(
    nodes$id %in% c("20a-DOMDiv200", "20b-Francis"), 0.34,
    ifelse(nodes$branch, 0.36, 0.42)
  )
  nodes$step_category <- paste0("step_", nodes$category)
  content_left <- nodes$x - nodes$half_w + nodes$step_band
  content_width <- 2 * nodes$half_w - nodes$step_band
  nodes$text_x <- ifelse(
    nodes$branch,
    content_left + content_width / 2,
    content_left + 0.10
  )
  nodes$text_y <- nodes$y + ifelse(nodes$branch, 0.09, 0)
  nodes$text_hjust <- ifelse(nodes$branch, 0.5, 0)
  nodes$text_size <- ifelse(
    nodes$id %in% c("20a-DOMDiv200", "20b-Francis"), 2.25,
    ifelse(nodes$branch, 2.55, 3.00)
  )
  nodes$number_size <- ifelse(
    nodes$id %in% c("20a-DOMDiv200", "20b-Francis"), 2.75, 3.10
  )
  nodes$status_x <- content_left + content_width / 2
  nodes$status_y <- nodes$y - 0.24

  panels <- data.frame(
    xmin = c(0.22, 2.77, 5.32, 8.57),
    xmax = c(2.68, 5.23, 8.48, 11.47),
    title = c(
      "I  MODEL FOUNDATION  ↓\n01–05",
      "II  STRUCTURE & DATA  ↑\n06–10",
      "III  CPUE, AGE & SELECTIVITY  ↓\n11–16",
      "IV  TAGS, EFFORT & WEIGHTING  ↑\n17–20"
    ),
    panel_key = c("panel_a", "panel_b", "panel_a", "panel_b"),
    stringsAsFactors = FALSE
  )
  panels$x <- (panels$xmin + panels$xmax) / 2

  node_lookup <- split(nodes, nodes$id)
  edge_rows <- list()
  add_edge <- function(from, to, kind = "carried", curvature = 0) {
    a <- node_lookup[[from]]
    b <- node_lookup[[to]]
    dx <- b$x - a$x
    dy <- b$y - a$y
    distance <- sqrt(dx^2 + dy^2)
    ux <- dx / distance
    uy <- dy / distance
    from_boundary <- 1 / max(abs(ux) / a$half_w, abs(uy) / a$half_h)
    to_boundary <- 1 / max(abs(ux) / b$half_w, abs(uy) / b$half_h)
    gap <- 0.025
    edge_rows[[length(edge_rows) + 1L]] <<- data.frame(
      x = a$x + (from_boundary + gap) * ux,
      y = a$y + (from_boundary + gap) * uy,
      xend = b$x - (to_boundary + gap) * ux,
      yend = b$y - (to_boundary + gap) * uy,
      kind = kind,
      curvature = curvature
    )
  }
  for (i in seq_len(length(selected_path) - 1L)) {
    add_edge(selected_path[[i]], selected_path[[i + 1L]])
  }
  add_edge("14-NewAgeData", "15a-REG075", "alternative")
  add_edge("19-EffortCreep", "20a-DOMDiv200", "alternative")
  add_edge("19-EffortCreep", "20b-Francis", "alternative")
  edges <- do.call(rbind, edge_rows)

  palette <- c(
    carried = "#4F8589",
    selected = "#126E73",
    alternative = "#C86616",
    final = "#123F48"
  )
  fills <- c(
    carried = "#FFFFFF",
    selected = "#FFFFFF",
    alternative = "#FFFFFF",
    final = "#FFFFFF",
    step_carried = "#315F68",
    step_selected = "#0B555A",
    step_alternative = "#B8560F",
    step_final = "#0A333B",
    panel_a = "#F3F7F7",
    panel_b = "#FAFBFB"
  )
  caption <- paste(
    "BET 2026 stepwise development pathway. Solid teal arrows show the selected",
    "carry-forward sequence; dashed orange arrows identify alternative age-data",
    "and composition-data weighting models."
  )

  plot <- ggplot2::ggplot() +
    ggplot2::geom_rect(
      data = panels,
      ggplot2::aes(
        xmin = xmin, xmax = xmax, ymin = 0.33, ymax = 6.35,
        fill = panel_key
      ),
      colour = "#DCE5E5",
      linewidth = 0.48
    ) +
    ggplot2::geom_rect(
      data = panels,
      ggplot2::aes(xmin = xmin, xmax = xmax, ymin = 6.29, ymax = 6.35),
      inherit.aes = FALSE,
      fill = "#315F68",
      colour = NA
    ) +
    ggplot2::geom_segment(
      data = panels,
      ggplot2::aes(x = xmin + 0.15, xend = xmax - 0.15, y = 5.96, yend = 5.96),
      inherit.aes = FALSE,
      colour = "#D5E0E0",
      linewidth = 0.45
    ) +
    ggplot2::geom_text(
      data = panels,
      ggplot2::aes(x = x, y = 6.13, label = title),
      inherit.aes = FALSE,
      colour = "#315F68",
      fontface = "bold",
      lineheight = 0.92,
      size = 2.28
    ) +
    ggplot2::geom_segment(
      data = edges[edges$curvature == 0, , drop = FALSE],
      ggplot2::aes(
        x = x, y = y, xend = xend, yend = yend,
        colour = kind, linetype = kind
      ),
      linewidth = 0.76,
      lineend = "round",
      arrow = grid::arrow(length = grid::unit(1.7, "mm"), type = "closed")
    ) +
    ggplot2::geom_curve(
      data = edges[edges$curvature > 0, , drop = FALSE],
      ggplot2::aes(
        x = x, y = y, xend = xend, yend = yend,
        colour = kind, linetype = kind
      ),
      curvature = 0.32,
      linewidth = 0.76,
      lineend = "round",
      arrow = grid::arrow(length = grid::unit(1.7, "mm"), type = "closed")
    ) +
    ggplot2::geom_curve(
      data = edges[edges$curvature < 0, , drop = FALSE],
      ggplot2::aes(
        x = x, y = y, xend = xend, yend = yend,
        colour = kind, linetype = kind
      ),
      curvature = -0.32,
      linewidth = 0.76,
      lineend = "round",
      arrow = grid::arrow(length = grid::unit(1.7, "mm"), type = "closed")
    ) +
    ggplot2::geom_rect(
      data = nodes,
      ggplot2::aes(
        xmin = x - half_w, xmax = x + half_w,
        ymin = y - half_h, ymax = y + half_h,
        fill = category, colour = category
      ),
      linewidth = 0.66
    ) +
    ggplot2::geom_rect(
      data = nodes,
      ggplot2::aes(
        xmin = x - half_w, xmax = x - half_w + step_band,
        ymin = y - half_h, ymax = y + half_h,
        fill = step_category
      ),
      colour = NA
    ) +
    ggplot2::geom_text(
      data = nodes,
      ggplot2::aes(
        x = x - half_w + step_band / 2,
        y = y, label = step, size = number_size
      ),
      colour = "#FFFFFF",
      fontface = "bold"
    ) +
    ggplot2::geom_text(
      data = nodes,
      ggplot2::aes(
        x = text_x, y = text_y, label = name, hjust = text_hjust,
        colour = "dark",
        size = text_size
      ),
      lineheight = 0.92,
      fontface = "bold"
    ) +
    ggplot2::geom_label(
      data = nodes[nodes$category == "alternative", , drop = FALSE],
      ggplot2::aes(x = status_x, y = status_y, label = status),
      inherit.aes = FALSE,
      fill = "#C86616",
      colour = "#FFFFFF",
      label.padding = grid::unit(0.055, "lines"),
      label.r = grid::unit(0.05, "lines"),
      linewidth = 0,
      fontface = "bold",
      size = 1.75
    ) +
    ggplot2::geom_label(
      data = nodes[nodes$category %in% c("selected", "final"), , drop = FALSE],
      ggplot2::aes(x = status_x, y = status_y, label = status),
      inherit.aes = FALSE,
      fill = "#126E73",
      colour = "#FFFFFF",
      label.padding = grid::unit(0.055, "lines"),
      label.r = grid::unit(0.05, "lines"),
      linewidth = 0,
      fontface = "bold",
      size = 1.75
    ) +
    ggplot2::annotate(
      "text", x = 0.25, y = 7.08,
      label = "BET 2026 STEPWISE DEVELOPMENT PATHWAY",
      hjust = 0,
      colour = "#253E45",
      fontface = "bold",
      size = 4.15
    ) +
    ggplot2::annotate(
      "segment", x = 0.28, xend = 0.72, y = 6.72, yend = 6.72,
      colour = "#4F8589", linewidth = 0.9,
      arrow = grid::arrow(length = grid::unit(1.5, "mm"), type = "closed")
    ) +
    ggplot2::annotate(
      "text", x = 0.80, y = 6.72, label = "selected carry-forward",
      hjust = 0, colour = "#5C7075", size = 2.35
    ) +
    ggplot2::annotate(
      "segment", x = 2.42, xend = 2.76, y = 6.72, yend = 6.72,
      colour = "#C86616", linewidth = 0.9, linetype = "22"
    ) +
    ggplot2::annotate(
      "segment", x = 2.76, xend = 2.88, y = 6.72, yend = 6.72,
      colour = "#C86616", linewidth = 0.9,
      arrow = grid::arrow(length = grid::unit(1.5, "mm"), type = "closed")
    ) +
    ggplot2::annotate(
      "text", x = 2.98, y = 6.72, label = "comparison branch",
      hjust = 0, colour = "#5C7075", size = 2.35
    ) +
    ggplot2::annotate(
      "text", x = 5.00, y = 6.72,
      label = "Follow the arrows; numbered groups preserve development order",
      hjust = 0, colour = "#7A8A8E", size = 2.20
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
    ggplot2::scale_size_identity() +
    ggplot2::coord_cartesian(
      xlim = c(0.16, 11.53), ylim = c(0.29, 7.20),
      expand = FALSE, clip = "off"
    ) +
    ggplot2::theme_void(base_family = "sans") +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "#FFFFFF", colour = NA),
      plot.margin = ggplot2::margin(2, 2, 2, 2)
    )

  figure_dir <- file.path(output_dir, "figures")
  dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
  png_path <- file.path(figure_dir, paste0(basename, ".png"))
  ggplot2::ggsave(
    filename = png_path,
    plot = plot,
    device = ragg::agg_png,
    width = 11.69,
    height = 7.35,
    units = "in",
    dpi = 300,
    background = "#FFFFFF"
  )

  invisible(list(png = png_path, nodes = nodes, caption = caption))
}

if (sys.nframe() == 0L) {
  build_stepwise_dag()
}
