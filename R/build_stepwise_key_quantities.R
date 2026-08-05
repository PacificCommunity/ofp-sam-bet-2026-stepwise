# Build compact, A4-ready stepwise figures from the report time-series bundle.

stepwise_key_palette <- function(n) {
  grDevices::colorRampPalette(c("#d9e4e7", "#9fc5ca", "#4f929b", "#0f5863"))(n)
}

stepwise_line_styles <- function(map) {
  # Paul Tol-inspired muted colours combined with three line types give every
  # configuration a unique, colour-vision-conscious key without neon colours.
  colours <- rep(
    c("#332288", "#117733", "#4477AA", "#44AA99", "#88CCEE", "#DDCC77", "#AA4499", "#882255"),
    length.out = nrow(map)
  )
  linetypes <- rep(c("solid", "22", "42"), each = 8L, length.out = nrow(map))
  colours[[nrow(map)]] <- "#c92f2a"
  linetypes[[nrow(map)]] <- "solid"
  names(colours) <- map$row
  names(linetypes) <- map$row
  list(colours = colours, linetypes = linetypes)
}

stepwise_key_theme <- function(base_size = 9.2) {
  ggplot2::theme_minimal(base_family = "sans", base_size = base_size) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = "#dce5e8", linewidth = 0.32),
      axis.line = ggplot2::element_line(colour = "#425a66", linewidth = 0.35),
      axis.ticks = ggplot2::element_line(colour = "#425a66", linewidth = 0.35),
      axis.title = ggplot2::element_text(colour = "#17394b", face = "bold"),
      axis.text = ggplot2::element_text(colour = "#3f5866"),
      plot.margin = ggplot2::margin(5, 7, 5, 5),
      plot.tag = ggplot2::element_text(colour = "#17394b", face = "bold", size = base_size),
      legend.position = "bottom",
      legend.box = "vertical",
      legend.title = ggplot2::element_text(face = "bold", colour = "#17394b"),
      legend.text = ggplot2::element_text(colour = "#3f5866")
    )
}

stepwise_save_a4_figure <- function(plot, png, pdf, width = 7.15, height = 9.25) {
  dir.create(dirname(png), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(
    filename = png, plot = plot, width = width, height = height,
    units = "in", dpi = 300, device = ragg::agg_png, background = "white"
  )
  ggplot2::ggsave(
    filename = pdf, plot = plot, width = width, height = height,
    units = "in", device = grDevices::cairo_pdf, bg = "white"
  )
}

stepwise_metric_spec <- function() {
  list(
    depletion = list(
      column = "depletion",
      recent = "Depletion recent mean",
      label = expression(italic(SB) / italic(SB)[italic(F) == 0]),
      lrp = TRUE
    ),
    recruitment = list(
      column = "recruitment",
      recent = "Recruitment recent mean",
      label = "Recruitment (millions of fish)",
      lrp = FALSE
    ),
    spawning_potential = list(
      column = "spawning_potential",
      recent = "Spawning potential recent mean",
      label = expression("Spawning potential"~(10^3~t)),
      lrp = FALSE
    ),
    fishing_mortality = list(
      column = "fishing_mortality",
      recent = "Fishing mortality recent mean",
      label = expression(italic(F)~(year^{-1})),
      lrp = FALSE
    )
  )
}

stepwise_payload_rep_text <- function(payload_file) {
  payload <- readRDS(payload_file)
  artifact <- payload$artifacts$files$rep
  if (is.null(artifact) || !identical(artifact$storage, "raw-file") || !is.raw(artifact$bytes)) {
    stop("The compact payload does not contain a raw REP artifact: ", payload_file, call. = FALSE)
  }
  bytes <- artifact$bytes
  if (identical(artifact$compression, "gzip")) {
    bytes <- memDecompress(bytes, type = "gzip")
  } else if (!identical(artifact$compression, "none")) {
    stop("Unsupported REP compression in ", payload_file, ": ", artifact$compression, call. = FALSE)
  }
  rawToChar(bytes)
}

stepwise_rep_scalar <- function(rep_text, label) {
  lines <- trimws(strsplit(rep_text, "\n", fixed = TRUE)[[1L]])
  marker <- which(lines == paste0("# ", label))
  if (length(marker) != 1L) {
    stop("Expected exactly one REP field named '", label, "'.", call. = FALSE)
  }
  following <- lines[seq.int(marker + 1L, min(length(lines), marker + 5L))]
  following <- following[nzchar(following) & !startsWith(following, "#")]
  value <- suppressWarnings(as.numeric(sub("[dD]", "E", following[[1L]])))
  if (!is.finite(value)) stop("REP field '", label, "' is not numeric.", call. = FALSE)
  value
}

stepwise_period_label <- function(years) paste0(min(years), "\u2013", max(years))

stepwise_window_values <- function(data, years, column, model_token) {
  selected <- data[data$year %in% years, c("year", column), drop = FALSE]
  if (!identical(sort(unique(as.integer(selected$year))), as.integer(years))) {
    stop("The required ", column, " window is incomplete for ", model_token, ".", call. = FALSE)
  }
  value <- suppressWarnings(as.numeric(selected[[column]]))
  if (length(value) != length(years) || any(!is.finite(value))) {
    stop("The required ", column, " values are invalid for ", model_token, ".", call. = FALSE)
  }
  value
}

stepwise_official_recent_quantities <- function(series, map) {
  rows <- lapply(seq_len(nrow(map)), function(i) {
    token <- map$step_id[[i]]
    model <- series[series$model_token == token & series$region == "All", , drop = FALSE]
    if (!nrow(model)) stop("No stock-wide time series found for ", token, ".", call. = FALSE)
    terminal <- max(as.integer(model$year), na.rm = TRUE)
    sb_years <- seq.int(terminal - 3L, terminal)
    sbf0_years <- seq.int(terminal - 10L, terminal - 1L)
    f_years <- seq.int(terminal - 4L, terminal - 1L)
    sb_recent <- mean(stepwise_window_values(model, sb_years, "spawning_potential", token))
    sbf0_recent <- mean(stepwise_window_values(model, sbf0_years, "spawning_potential_nofish", token))

    sources <- unique(as.character(model$source_file[nzchar(model$source_file)]))
    sources <- sources[file.exists(sources)]
    if (length(sources) != 1L) {
      stop("Expected one existing compact payload source for ", token, ".", call. = FALSE)
    }
    rep_text <- stepwise_payload_rep_text(sources[[1L]])
    fmult <- stepwise_rep_scalar(rep_text, "F multiplier at MSY")
    sb_msy_t <- stepwise_rep_scalar(rep_text, "Adult biomass at MSY")
    if (fmult <= 0 || sb_msy_t <= 0) stop("Invalid native MSY scalar for ", token, ".", call. = FALSE)

    data.frame(
      Step = map$row[[i]], Configuration = token, `Terminal year` = terminal,
      `SB recent period` = stepwise_period_label(sb_years),
      `SB F=0 period` = stepwise_period_label(sbf0_years),
      `F recent period` = stepwise_period_label(f_years),
      `SB recent (10³ t)` = sb_recent,
      `SB F=0 (10³ t)` = sbf0_recent,
      `SB recent / SB F=0` = sb_recent / sbf0_recent,
      `SB recent / SB MSY` = sb_recent * 1000 / sb_msy_t,
      `F recent / F MSY` = 1 / fmult,
      `F multiplier at MSY` = fmult,
      `SB MSY (t)` = sb_msy_t,
      check.names = FALSE, stringsAsFactors = FALSE
    )
  })
  quantities <- do.call(rbind, rows)
  rownames(quantities) <- NULL

  # Job 21641 / Step 22 is the numerical anchor. These values independently
  # reproduce the native MFCL quantities already reported for that model.
  diagnostic <- quantities[quantities$Configuration == "22-Diagnostic", , drop = FALSE]
  if (nrow(diagnostic) != 1L || diagnostic[["Terminal year"]] != 2024L ||
      diagnostic[["SB recent period"]] != "2021\u20132024" ||
      diagnostic[["SB F=0 period"]] != "2014\u20132023" ||
      diagnostic[["F recent period"]] != "2020\u20132023") {
    stop("Step 22 official recent-period audit failed.", call. = FALSE)
  }
  expected <- c(0.1731393, 1.025495, 1.143641)
  actual <- unlist(diagnostic[1L, c(
    "SB recent / SB F=0", "SB recent / SB MSY", "F recent / F MSY"
  )], use.names = FALSE)
  if (any(abs(actual - expected) > 5e-7)) {
    stop(
      "Step 22 native stock-status audit failed: expected ",
      paste(expected, collapse = ", "), "; calculated ",
      paste(format(actual, digits = 9), collapse = ", "), ".",
      call. = FALSE
    )
  }
  quantities
}

stepwise_status_spec <- function() {
  list(
    depletion = list(
      column = "SB recent / SB F=0",
      label = expression(italic(SB)[recent] / italic(SB)[italic(F) == 0]),
      reference = 0.2, reference_label = "LRP"
    ),
    biomass_msy = list(
      column = "SB recent / SB MSY",
      label = expression(italic(SB)[recent] / italic(SB)[MSY]),
      reference = 1, reference_label = NULL
    ),
    fishing_msy = list(
      column = "F recent / F MSY",
      label = expression(italic(F)[recent] / italic(F)[MSY]),
      reference = 1, reference_label = NULL
    ),
    spawning_potential = list(
      column = "SB recent (10³ t)",
      label = expression(italic(SB)[recent]~(10^3~t)),
      reference = NA_real_, reference_label = NULL
    )
  )
}

stepwise_model_map <- function(source_index, series) {
  required <- c("order", "row", "step_id")
  missing <- setdiff(required, names(source_index))
  if (length(missing)) stop("Source index is missing: ", paste(missing, collapse = ", "), call. = FALSE)
  map <- source_index[, required, drop = FALSE]
  map$order <- as.integer(map$order)
  map$row <- as.character(map$row)
  map$step_id <- as.character(map$step_id)
  if (anyDuplicated(map$order) || anyDuplicated(map$step_id)) {
    stop("Source-index order and step_id values must be unique.", call. = FALSE)
  }
  missing_series <- setdiff(map$step_id, unique(as.character(series$model_token)))
  if (length(missing_series)) {
    stop("No time series found for: ", paste(missing_series, collapse = ", "), call. = FALSE)
  }
  map
}

stepwise_trajectory_panel <- function(data, spec, map, show_x = TRUE) {
  values <- data[[spec$column]]
  plot_data <- data[is.finite(data$year) & is.finite(values), , drop = FALSE]
  plot_data$value <- plot_data[[spec$column]]
  final_order <- max(map$order)
  final <- plot_data[plot_data$order == final_order, , drop = FALSE]
  plot_data$row <- factor(plot_data$row, levels = map$row)
  styles <- stepwise_line_styles(map)
  ymax <- max(plot_data$value, na.rm = TRUE)
  if (identical(spec$column, "depletion")) ymax <- max(1, ymax)

  plot <- ggplot2::ggplot() +
    ggplot2::geom_line(
      data = plot_data,
      ggplot2::aes(x = year, y = value, group = model_token, colour = row, linetype = row),
      linewidth = 0.48, alpha = 0.86, lineend = "round"
    ) +
    ggplot2::geom_line(
      data = final,
      ggplot2::aes(x = year, y = value, group = model_token),
      colour = "#c92f2a", linewidth = 1.08, lineend = "round"
    ) +
    ggplot2::scale_colour_manual(
      values = styles$colours, breaks = map$row,
      name = "Step (see pathway and table)",
      guide = ggplot2::guide_legend(
        title.position = "top", title.hjust = 0.5, nrow = 4, byrow = TRUE,
        keywidth = grid::unit(7.5, "mm"), keyheight = grid::unit(3.1, "mm"),
        override.aes = list(alpha = 1, linewidth = 0.75)
      )
    ) +
    ggplot2::scale_linetype_manual(
      values = styles$linetypes, breaks = map$row,
      name = "Step (see pathway and table)"
    ) +
    ggplot2::scale_x_continuous(
      breaks = seq(1960, 2020, by = 20),
      expand = ggplot2::expansion(mult = c(0.015, 0.015))
    ) +
    ggplot2::scale_y_continuous(
      limits = c(0, ymax * 1.035), expand = ggplot2::expansion(mult = c(0, 0.015))
    ) +
    ggplot2::labs(x = if (show_x) "Year" else NULL, y = spec$label) +
    stepwise_key_theme()

  if (isTRUE(spec$lrp)) {
    xmin <- min(plot_data$year, na.rm = TRUE)
    plot <- plot +
      ggplot2::geom_hline(yintercept = 0.2, colour = "#b6403d", linewidth = 0.48, linetype = "22") +
      ggplot2::annotate(
        "text", x = xmin + 1.5, y = 0.2, label = "LRP", colour = "#a93432",
        hjust = 0, vjust = -0.45, size = 3.0, fontface = "bold"
      )
  }
  plot
}

stepwise_recent_panel <- function(data, spec, map, show_x = FALSE) {
  plot_data <- data.frame(
    order = map$order,
    row = map$row,
    value = suppressWarnings(as.numeric(data[[spec$column]][match(map$step_id, data$Configuration)])),
    stringsAsFactors = FALSE
  )
  if (any(!is.finite(plot_data$value))) {
    stop("Recent values are incomplete for ", spec$column, ".", call. = FALSE)
  }
  final_order <- max(plot_data$order)
  ymax <- max(plot_data$value, na.rm = TRUE)
  if (identical(spec$column, "SB recent / SB F=0")) ymax <- max(0.25, ymax)
  point_colours <- c(stepwise_key_palette(nrow(plot_data) - 1L), "#c92f2a")
  names(point_colours) <- plot_data$row

  plot <- ggplot2::ggplot(plot_data, ggplot2::aes(order, value)) +
    ggplot2::geom_line(colour = "#315f68", linewidth = 0.62, lineend = "round") +
    ggplot2::geom_point(ggplot2::aes(colour = row), size = 2.0) +
    ggplot2::geom_point(
      data = plot_data[plot_data$order == final_order, , drop = FALSE],
      colour = "#c92f2a", fill = "white", shape = 21, stroke = 1.05, size = 3.1
    ) +
    ggplot2::scale_colour_manual(values = point_colours, guide = "none") +
    ggplot2::scale_x_continuous(
      breaks = plot_data$order, labels = plot_data$row,
      expand = ggplot2::expansion(add = c(0.45, 0.45))
    ) +
    ggplot2::scale_y_continuous(
      limits = c(0, ymax * 1.07), expand = ggplot2::expansion(mult = c(0, 0.015))
    ) +
    ggplot2::labs(x = if (show_x) "Model-development step" else NULL, y = spec$label) +
    stepwise_key_theme(base_size = 8.8) +
    ggplot2::theme(
      legend.position = "none",
      axis.text.x = if (show_x) {
        ggplot2::element_text(angle = 55, hjust = 1, vjust = 1, size = 7.3)
      } else {
        ggplot2::element_blank()
      },
      axis.ticks.x = if (show_x) ggplot2::element_line(colour = "#425a66") else ggplot2::element_blank()
    )

  if (is.finite(spec$reference)) {
    plot <- plot +
      ggplot2::geom_hline(
        yintercept = spec$reference, colour = "#b6403d", linewidth = 0.48, linetype = "22"
      )
    if (!is.null(spec$reference_label)) {
      plot <- plot + ggplot2::annotate(
        "text", x = min(plot_data$order) + 0.3, y = spec$reference,
        label = spec$reference_label, colour = "#a93432", hjust = 0,
        vjust = -0.4, size = 2.8, fontface = "bold"
      )
    }
  }
  plot
}

stepwise_custom_figure_index <- function(series, map) {
  captions <- c(
    paste0(
      "Annual estimates of dynamic spawning depletion, recruitment, spawning potential and fishing mortality ",
      "across the 23 model configurations evaluated during stepwise development. The colour and line-style key ",
      "identifies each configuration by Step number; the final Diagnostic model (Step 22) is shown in red. The dashed ",
      "line in the depletion panel marks the limit reference point (LRP = 0.2)."
    ),
    paste0(
      "Stock-status quantities across the 23 model configurations evaluated during stepwise development. For each ",
      "configuration, recent periods are defined relative to its terminal year: spawning biomass uses T-3 to T, ",
      "unfished spawning biomass uses T-10 to T-1, and fishing mortality uses T-4 to T-1. For the final Diagnostic ",
      "model (T = 2024), these periods are 2021-2024, 2014-2023 and 2020-2023, respectively. Step 22 is outlined ",
      "in red. The depletion line marks the limit reference point (LRP = 0.2); MSY-ratio lines mark 1.0."
    )
  )
  latex <- c(
    paste0(
      "Annual estimates of dynamic spawning depletion ($SB/SB_{F=0}$), recruitment, spawning potential, and ",
      "fishing mortality across the 23 model configurations evaluated during stepwise development. The colour ",
      "and line-style key identifies each configuration by Step number; the final Diagnostic model (Step~22) is shown ",
      "in red. The dashed line in the depletion panel marks the limit reference point (LRP = 0.2)."
    ),
    paste0(
      "Stock-status quantities across the 23 model configurations evaluated during stepwise development. For each ",
      "configuration, recent periods are defined relative to its terminal year: spawning biomass uses $T-3$ to $T$, ",
      "unfished spawning biomass uses $T-10$ to $T-1$, and fishing mortality uses $T-4$ to $T-1$. For the final ",
      "Diagnostic model ($T=2024$), these periods are 2021--2024, 2014--2023, and 2020--2023, respectively. ",
      "Step~22 is outlined in red. The depletion line marks the limit reference point (LRP = 0.2); MSY-ratio ",
      "lines mark 1.0."
    )
  )
  data.frame(
    figure = c("stepwise-key-quantity-trajectories", "stepwise-key-quantity-changes"),
    file = c("stepwise-key-quantity-trajectories.png", "stepwise-key-quantity-changes.png"),
    relative_path = c(
      "figures/stepwise-key-quantity-trajectories.png",
      "figures/stepwise-key-quantity-changes.png"
    ),
    label = c("Key-quantity trajectories", "Key quantities by model-development step"),
    caption = captions,
    latex_caption = latex,
    alt_text = captions,
    description = c(
      "A4 four-panel annual time-series comparison of all stepwise model configurations.",
      "A4 four-panel comparison of native stock-status quantities by model-development step."
    ),
    format = "png", rows = c(nrow(series), nrow(map) * 4L), models = nrow(map),
    width = 7.15, height = 9.25, dpi = 300L, status = "ok",
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

stepwise_custom_table_index <- function(existing, rows) {
  keep <- if (is.data.frame(existing) && nrow(existing)) {
    existing[existing$table != "stepwise_recent_key_quantities", , drop = FALSE]
  } else {
    data.frame()
  }
  added <- data.frame(
    table = "stepwise_recent_key_quantities",
    file = "stepwise-recent-key-quantities.csv",
    relative_path = "tables/stepwise-recent-key-quantities.csv",
    label = "Stock-status quantities by step",
    caption = paste0(
      "Native stock-status quantities and exact recent periods for each model configuration evaluated during ",
      "stepwise development. Periods are defined relative to each configuration's terminal year."
    ),
    description = "Values plotted in the model-development step comparison figure.",
    format = "csv", rows = nrow(rows), columns = ncol(rows), status = "ok",
    stringsAsFactors = FALSE, check.names = FALSE
  )
  if (!nrow(keep)) return(added)
  missing_added <- setdiff(names(keep), names(added))
  for (name in missing_added) added[[name]] <- NA
  missing_keep <- setdiff(names(added), names(keep))
  for (name in missing_keep) keep[[name]] <- NA
  rbind(added[, names(keep), drop = FALSE], keep)
}

build_stepwise_key_quantities <- function(result_dir, source_index) {
  series_file <- file.path(result_dir, "mfclshiny-report-depletion-data.csv")
  figure_index_file <- file.path(result_dir, "figure-index.csv")
  table_index_file <- file.path(result_dir, "table-index.csv")
  existing_figures <- if (file.exists(figure_index_file)) {
    utils::read.csv(figure_index_file, check.names = FALSE, stringsAsFactors = FALSE)
  } else data.frame()
  existing_tables <- if (file.exists(table_index_file)) {
    utils::read.csv(table_index_file, check.names = FALSE, stringsAsFactors = FALSE)
  } else data.frame()

  if (!file.exists(series_file)) {
    return(list(figure_index = existing_figures, table_index = existing_tables))
  }
  for (package in c("ggplot2", "patchwork", "ragg")) {
    if (!requireNamespace(package, quietly = TRUE)) stop(package, " is required.", call. = FALSE)
  }

  series <- utils::read.csv(series_file, check.names = FALSE, stringsAsFactors = FALSE)
  map <- stepwise_model_map(source_index, series)
  matched <- match(series$model_token, map$step_id)
  series$order <- map$order[matched]
  series$row <- map$row[matched]
  if (any(is.na(series$order))) stop("Unmapped time-series model tokens were found.", call. = FALSE)

  specs <- stepwise_metric_spec()
  trajectory_panels <- Map(
    function(spec, index) stepwise_trajectory_panel(series, spec, map, show_x = index > 2L),
    specs, seq_along(specs)
  )
  trajectory <- patchwork::wrap_plots(trajectory_panels, ncol = 2, guides = "collect") +
    patchwork::plot_annotation(tag_levels = "a") &
    ggplot2::theme(legend.position = "bottom")

  recent <- stepwise_official_recent_quantities(series, map)
  status_specs <- stepwise_status_spec()
  recent_panels <- Map(
    function(spec, index) stepwise_recent_panel(recent, spec, map, show_x = index == length(status_specs)),
    status_specs, seq_along(status_specs)
  )
  changes <- patchwork::wrap_plots(recent_panels, ncol = 1, heights = c(1, 1, 1, 1.18)) +
    patchwork::plot_annotation(tag_levels = "a")

  figure_dir <- file.path(result_dir, "figures")
  stepwise_save_a4_figure(
    trajectory,
    file.path(figure_dir, "stepwise-key-quantity-trajectories.png"),
    file.path(figure_dir, "stepwise-key-quantity-trajectories.pdf")
  )
  stepwise_save_a4_figure(
    changes,
    file.path(figure_dir, "stepwise-key-quantity-changes.png"),
    file.path(figure_dir, "stepwise-key-quantity-changes.pdf")
  )

  recent_export <- recent
  dir.create(file.path(result_dir, "tables"), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    recent_export, file.path(result_dir, "tables", "stepwise-recent-key-quantities.csv"),
    row.names = FALSE, na = ""
  )

  figure_index <- stepwise_custom_figure_index(series, map)
  table_index <- stepwise_custom_table_index(existing_tables, recent_export)
  utils::write.csv(figure_index, figure_index_file, row.names = FALSE, na = "")
  utils::write.csv(figure_index, file.path(result_dir, "mfclshiny-figure-index.csv"), row.names = FALSE, na = "")
  utils::write.csv(table_index, table_index_file, row.names = FALSE, na = "")
  utils::write.csv(table_index, file.path(result_dir, "mfclshiny-table-index.csv"), row.names = FALSE, na = "")
  list(figure_index = figure_index, table_index = table_index)
}
