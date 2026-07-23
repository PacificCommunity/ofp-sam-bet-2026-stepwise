# Build a portable, report-ready account of the BET 2026 stepwise pathway.

stepwise_html_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

stepwise_scientific_html <- function(x) {
  x <- stepwise_html_escape(x)
  x <- gsub("Nmax", "<i>N</i><sub>max</sub>", x, fixed = TRUE)
  x
}

stepwise_latex_escape <- function(x) {
  x <- as.character(x)
  replacements <- c(
    "\\" = "\\textbackslash{}",
    "&" = "\\&", "%" = "\\%", "$" = "\\$",
    "#" = "\\#", "_" = "\\_", "{" = "\\{",
    "}" = "\\}", "~" = "\\textasciitilde{}",
    "^" = "\\textasciicircum{}"
  )
  for (from in names(replacements)) {
    x <- gsub(from, replacements[[from]], x, fixed = TRUE)
  }
  x
}

stepwise_sentence <- function(x) {
  x <- trimws(as.character(x))
  empty <- is.na(x) | !nzchar(x)
  x[empty] <- ""
  use <- !empty
  x[use] <- paste0(toupper(substr(x[use], 1L, 1L)), substring(x[use], 2L))
  needs_stop <- use & !grepl("[.!?]$", x)
  x[needs_stop] <- paste0(x[needs_stop], ".")
  x
}

stepwise_references <- c(
  paste0(
    "Peatman, T., Castillo-Jordán, C., Teears, T., Magnusson, A., Kim, K., ",
    "Hampton, J. and Hamer, P. (2026). Analysis of size frequency data for the ",
    "2026 yellowfin and bigeye assessments. WCPFC-SC22-2026-SA-IP06."
  ),
  paste0(
    "Day, J., Magnusson, A., Teears, T., Hampton, J., Davies, N., ",
    "Castillo-Jordán, C., Peatman, T., Scott, R., Scutt Phillips, J., ",
    "McKechnie, S., Scott, F., Yao, N., Natadra, R., Pilling, G., Williams, P. ",
    "and Hamer, P. (2023). Stock assessment of bigeye tuna in the western and ",
    "central Pacific Ocean: 2023. WCPFC-SC19-2023/SA-WP-05, Rev. 2."
  ),
  paste0(
    "Lorenzen, K. (1996). The relationship between body weight and natural ",
    "mortality in juvenile and adult fish: a comparison of natural ecosystems ",
    "and aquaculture. Journal of Fish Biology, 49, 627-642. ",
    "doi:10.1111/j.1095-8649.1996.tb00060.x."
  ),
  paste0(
    "Francis, R.I.C.C. (2011). Data weighting in statistical fisheries stock ",
    "assessment models. Canadian Journal of Fisheries and Aquatic Sciences, 68, ",
    "1124-1138. doi:10.1139/F2011-025."
  ),
  paste0(
    "Thorson, J.T., Johnson, K.F., Methot, R.D. and Taylor, I.G. (2017). ",
    "Model-based estimates of effective sample size in stock assessment models ",
    "using the Dirichlet-multinomial distribution. Fisheries Research, 192, ",
    "84-93. doi:10.1016/j.fishres.2016.06.005."
  ),
  paste0(
    "Davies, N., Fournier, D.A., Hampton, J., Kleiber, P., Bouye, F., Kim, K., ",
    "Magnusson, A. and Hoyle, S. (2026). MULTIFAN-CL User's Guide, version ",
    "2.2.7.8. July 13, 2026."
  )
)

stepwise_reference_urls <- c(
  "https://meetings.wcpfc.int/node/32346",
  "https://meetings.wcpfc.int/node/19353",
  "https://doi.org/10.1111/j.1095-8649.1996.tb00060.x",
  "https://doi.org/10.1139/F2011-025",
  "https://doi.org/10.1016/j.fishres.2016.06.005",
  paste0(
    "https://github.com/PacificCommunity/ofp-sam-mfcl-manual/blob/",
    "4503c2abd234f3be95ec73e4375cf19df69859e2/MFCL-manual_MASTER.pdf"
  )
)

stepwise_references_bibtex <- paste0(
  "@techreport{PeatmanEtAl2026SizeFrequency,\n",
  "  author = {Peatman, Tom and Castillo-Jord{\\'a}n, Claudio and Teears, Thom and ",
  "Magnusson, Arni and Kim, Kyuhan and Hampton, John and Hamer, Paul},\n",
  "  title = {Analysis of size frequency data for the 2026 yellowfin and bigeye assessments},\n",
  "  institution = {Western and Central Pacific Fisheries Commission},\n",
  "  number = {WCPFC-SC22-2026-SA-IP06},\n",
  "  url = {https://meetings.wcpfc.int/node/32346},\n",
  "  year = {2026}\n",
  "}\n\n",
  "@techreport{DayEtAl2023BET,\n",
  "  author = {Day, J. and Magnusson, A. and Teears, T. and Hampton, J. and ",
  "Davies, N. and Castillo-Jord{\\'a}n, C. and Peatman, T. and Scott, R. and ",
  "Scutt Phillips, J. and McKechnie, S. and Scott, F. and Yao, N. and ",
  "Natadra, R. and Pilling, G. and Williams, P. and Hamer, P.},\n",
  "  title = {Stock assessment of bigeye tuna in the western and central Pacific Ocean: 2023},\n",
  "  institution = {Western and Central Pacific Fisheries Commission},\n",
  "  number = {WCPFC-SC19-2023/SA-WP-05, Rev. 2},\n",
  "  url = {https://meetings.wcpfc.int/node/19353},\n",
  "  year = {2023}\n",
  "}\n\n",
  "@article{Lorenzen1996NaturalMortality,\n",
  "  author = {Lorenzen, Kai},\n",
  "  title = {The relationship between body weight and natural mortality in juvenile and adult fish: a comparison of natural ecosystems and aquaculture},\n",
  "  journal = {Journal of Fish Biology},\n",
  "  volume = {49},\n",
  "  number = {4},\n",
  "  pages = {627--642},\n",
  "  year = {1996},\n",
  "  doi = {10.1111/j.1095-8649.1996.tb00060.x}\n",
  "}\n\n",
  "@article{Francis2011DataWeighting,\n",
  "  author = {Francis, R. I. C. C.},\n",
  "  title = {Data weighting in statistical fisheries stock assessment models},\n",
  "  journal = {Canadian Journal of Fisheries and Aquatic Sciences},\n",
  "  volume = {68},\n",
  "  number = {6},\n",
  "  pages = {1124--1138},\n",
  "  year = {2011},\n",
  "  doi = {10.1139/F2011-025}\n",
  "}\n\n",
  "@article{ThorsonEtAl2017DMESS,\n",
  "  author = {Thorson, James T. and Johnson, Kelli F. and Methot, Richard D. and Taylor, Ian G.},\n",
  "  title = {Model-based estimates of effective sample size in stock assessment models using the Dirichlet-multinomial distribution},\n",
  "  journal = {Fisheries Research},\n",
  "  volume = {192},\n",
  "  pages = {84--93},\n",
  "  year = {2017},\n",
  "  doi = {10.1016/j.fishres.2016.06.005}\n",
  "}\n\n",
  "@manual{DaviesEtAl2026MFCLGuide,\n",
  "  author = {Davies, Nick and Fournier, David A. and Hampton, John and ",
  "Kleiber, Pierre and Bouye, Fabrice and Kim, Kyuhan and Magnusson, Arni and Hoyle, Simon},\n",
  "  title = {{MULTIFAN-CL} User's Guide},\n",
  "  note = {Version 2.2.7.8},\n",
  "  month = jul,\n",
  "  url = {https://github.com/PacificCommunity/ofp-sam-mfcl-manual/blob/4503c2abd234f3be95ec73e4375cf19df69859e2/MFCL-manual_MASTER.pdf},\n",
  "  year = {2026}\n",
  "}"
)

stepwise_dm_configuration <- data.frame(
  setting = c(
    "Likelihood",
    "Fishery groups",
    "Group parameters",
    "ESS upper bound",
    "Length-bin support"
  ),
  implementation = c(
    "Dirichlet-multinomial without random effects (flag 141 = 11).",
    "Eight groups covering all 33 fisheries (flag 68; Table XX).",
    "Group-specific log-concentration and relative-sample-size exponent, estimated within the model (flags 69 and 89; from phase 2).",
    "Nmax = 25 (flag 342; MFCL default = 1,000).",
    "Minimum span of five observed bins (flag 320 = 5); flag 313 = 0."
  ),
  basis = c(
    "Estimate extra-multinomial variation in length compositions (Thorson et al., 2017).",
    "Pool fisheries with similar gear and data roles while retaining major differences.",
    "Allow composition information to vary among groups and with relative sample size.",
    paste0(
      "Set using composition-level effective sample sizes from the Francis ",
      "reweighting as an empirical reference; 25 lies just above their ",
      "95th-percentile range (22.22-23.81 across 2,399 compositions)."
    ),
    "Apply the DM support rule; the robust-normal 1% tail control is not used."
  ),
  stringsAsFactors = FALSE
)

stepwise_dm_groups <- data.frame(
  group = paste0("G", 1:8),
  fisheries = c(
    "F1-F4, F6-F8, F10-F11",
    "F5, F9",
    "F12, F17-F18",
    "F19, F25-F26",
    "F20, F27-F28",
    "F14-F15",
    "F13, F16, F21-F24",
    "F29-F33"
  ),
  series = c(
    "LL.WEST.1; LL.EAST.1; LL.US.1; LL.ALL.2; LL.ARCH.3; LL.WEST.3; LL.EAST.3; LL.ALL.5; LL.AU.5",
    "LL.OS.2; LL.OS.3",
    "PS.JP.1; PS.ID.2; PS.PH.2",
    "PS.ASS.2; PS.ASS.WEST.3; PS.ASS.EAST.3",
    "PS.UNA.2; PS.UNA.WEST.3; PS.UNA.EAST.3",
    "HL.ID.2; HL.PH.2",
    "PL.JP.1; PL.ALL.2; DOM.ID.2; DOM.PH.2; DOM.VN.2; PL.ALL.WEST.3",
    "Index R1; Index R2; Index R3; Index R4; Index R5"
  ),
  grouping_basis = c(
    "Main longline composition process",
    "Offshore longline series with a distinct sampling history",
    "Purse-seine series without associated/unassociated set-type separation",
    "Associated purse-seine series",
    "Unassociated purse-seine series",
    "Handline series",
    "Other extraction fisheries pooled for stable estimation",
    "Regional indices sharing the relative-abundance reweighting procedure"
  ),
  stringsAsFactors = FALSE
)

stepwise_parse_job_map <- function(value) {
  value <- trimws(as.character(value %||% ""))
  if (!nzchar(value)) {
    return(data.frame(step_id = character(), job_number = integer()))
  }
  tokens <- trimws(unlist(strsplit(value, "[,;\\n]+")))
  tokens <- tokens[nzchar(tokens)]
  valid <- grepl("^[^=:#]+\\s*[=:#]\\s*#?[0-9]+$", tokens)
  if (!all(valid)) {
    stop(
      "STEPWISE_MODEL_JOBS must use step=job pairs, for example ",
      "01-Diag2023=14047,02-NewExe1003=14046.",
      call. = FALSE
    )
  }
  parts <- strsplit(tokens, "\\s*[=:#]\\s*")
  data.frame(
    step_id = trimws(vapply(parts, `[[`, character(1), 1L)),
    job_number = as.integer(sub("^#", "", trimws(vapply(parts, `[[`, character(1), 2L)))),
    stringsAsFactors = FALSE
  )
}

stepwise_collect_job_records <- function(x) {
  records <- list()
  visit <- function(value) {
    if (!is.list(value)) return(invisible(NULL))
    names_value <- names(value)
    if (length(names_value) &&
        any(c("job_number", "job") %in% names_value) &&
        any(c("job_id", "id") %in% names_value)) {
      number <- value[[intersect(c("job_number", "job"), names_value)[1L]]]
      id <- value[[intersect(c("job_id", "id"), names_value)[1L]]]
      if (length(number) && length(id)) {
        records[[length(records) + 1L]] <<- data.frame(
          job_number = suppressWarnings(as.integer(number[[1L]])),
          job_id = as.character(id[[1L]]),
          stringsAsFactors = FALSE
        )
      }
    }
    for (item in value) visit(item)
    invisible(NULL)
  }
  visit(x)
  if (!length(records)) {
    return(data.frame(job_number = integer(), job_id = character()))
  }
  unique(do.call(rbind, records))
}

stepwise_discover_results <- function(job_map, input_dir) {
  if (!nrow(job_map)) {
    return(transform(job_map, payload = character(), status = character()))
  }
  provenance_file <- file.path(input_dir, "kflow-provenance.json")
  provenance <- if (file.exists(provenance_file) &&
                    requireNamespace("jsonlite", quietly = TRUE)) {
    tryCatch(
      jsonlite::fromJSON(provenance_file, simplifyVector = FALSE),
      error = function(e) list()
    )
  } else {
    list()
  }
  records <- stepwise_collect_job_records(provenance)

  payloads <- vapply(job_map$job_number, function(job_number) {
    job_id <- records$job_id[match(job_number, records$job_number)]
    roots <- c(
      if (length(job_id) && !is.na(job_id)) file.path(input_dir, job_id) else character(),
      file.path(input_dir, paste0("job-", sprintf("%06d", job_number))),
      file.path(input_dir, as.character(job_number))
    )
    roots <- roots[dir.exists(roots)]
    found <- unique(unlist(lapply(roots, function(root) {
      list.files(
        root,
        pattern = "^model_payload[.]rds$",
        recursive = TRUE,
        full.names = TRUE
      )
    })))
    preferred <- found[grepl("/outputs/models/[^/]+/model_payload[.]rds$", found)]
    if (length(preferred)) preferred[[1L]] else if (length(found)) found[[1L]] else ""
  }, character(1))

  transform(
    job_map,
    payload = payloads,
    status = ifelse(nzchar(payloads), "Included", "Awaiting fitted-model output")
  )
}

stepwise_stage_table <- function(nodes, job_map) {
  table <- data.frame(
    step_id = nodes$step_id,
    step = sub("-.*$", "", nodes$step_id),
    change = if ("report_change" %in% names(nodes)) {
      trimws(as.character(nodes$report_change))
    } else {
      stepwise_sentence(nodes$change_axis)
    },
    rationale = stepwise_sentence(
      if ("report_purpose" %in% names(nodes)) {
        nodes$report_purpose
      } else {
        nodes$control_notes
      }
    ),
    stringsAsFactors = FALSE
  )
  if (nrow(job_map)) {
    table$job_number <- job_map$job_number[match(table$step_id, job_map$step_id)]
  } else {
    table$job_number <- NA_integer_
  }
  table
}

stepwise_table_html <- function(table, include_jobs = FALSE) {
  job_header <- if (include_jobs) "<th>Job</th>" else ""
  colgroup <- if (include_jobs) {
    paste0(
      "<col style=\"width:8%\"><col style=\"width:39%\">",
      "<col style=\"width:47%\"><col style=\"width:6%\">"
    )
  } else {
    paste0(
      "<col style=\"width:8%\"><col style=\"width:42%\">",
      "<col style=\"width:50%\">"
    )
  }
  rows <- vapply(seq_len(nrow(table)), function(i) {
    rationale <- trimws(table$rationale[[i]])
    job_cell <- if (include_jobs) {
      value <- table$job_number[[i]]
      paste0("<td class=\"job\">", if (is.na(value)) "" else paste0("#", value), "</td>")
    } else ""
    paste0(
      "<tr><td class=\"step-number\">", stepwise_html_escape(table$step[[i]]), "</td>",
      "<td>", stepwise_html_escape(table$change[[i]]), "</td>",
      "<td>", stepwise_html_escape(rationale), "</td>", job_cell, "</tr>"
    )
  }, character(1))
  paste0(
    "<table id=\"stage-table\"><colgroup>", colgroup, "</colgroup>",
    "<thead><tr><th>Step</th><th>Model change</th>",
    "<th>Rationale</th>", job_header,
    "</tr></thead><tbody>", paste(rows, collapse = ""), "</tbody></table>"
  )
}

stepwise_table_latex <- function(table, include_jobs = FALSE) {
  columns <- if (include_jobs) {
    paste0(
      "@{}>{\\centering\\arraybackslash}p{0.06\\linewidth}",
      ">{\\raggedright\\arraybackslash}p{0.38\\linewidth}",
      ">{\\raggedright\\arraybackslash}p{0.45\\linewidth}r@{}"
    )
  } else {
    paste0(
      "@{}>{\\centering\\arraybackslash}p{0.06\\linewidth}",
      ">{\\raggedright\\arraybackslash}p{0.41\\linewidth}",
      ">{\\raggedright\\arraybackslash}p{0.48\\linewidth}@{}"
    )
  }
  header <- if (include_jobs) {
    "Step & Model change & Rationale & Job"
  } else {
    "Step & Model change & Rationale"
  }
  rows <- vapply(seq_len(nrow(table)), function(i) {
    values <- c(
      paste0("\\textbf{", stepwise_latex_escape(table$step[[i]]), "}"),
      stepwise_latex_escape(table$change[[i]]),
      stepwise_latex_escape(table$rationale[[i]])
    )
    if (include_jobs) {
      values <- c(values, if (is.na(table$job_number[[i]])) "" else paste0("\\#", table$job_number[[i]]))
    }
    paste0(paste(values, collapse = " & "), " \\\\")
  }, character(1))
  paste0(
    "% Requires \\usepackage{booktabs,longtable,array}\n",
    "\\begingroup\n\\small\n\\setlength{\\tabcolsep}{4pt}\n\\renewcommand{\\arraystretch}{1.08}\n",
    "\\setlength{\\LTcapwidth}{\\linewidth}\n",
    "\\begin{longtable}{", columns, "}\n",
    "\\caption{Changes evaluated during stepwise development of the BET 2026 assessment and their rationale.}",
    "\\label{tab:bet-stepwise-development}\\\\\n",
    "\\toprule\n", header, " \\\\\n\\midrule\n\\endfirsthead\n",
    "\\toprule\n", header, " \\\\\n\\midrule\n\\endhead\n",
    paste(rows, collapse = "\n"), "\n\\bottomrule\n\\end{longtable}\n\\endgroup\n",
    "\\begingroup\\footnotesize\\sloppy\\setlength{\\emergencystretch}{2em}",
    "\\noindent\\textit{References:}\\par\n",
    paste0(stepwise_latex_escape(stepwise_references), "\\par", collapse = "\n"),
    "\\endgroup\n"
  )
}

stepwise_named_table_html <- function(table, id, headers, widths,
                                      first_column_class = "") {
  stopifnot(length(headers) == ncol(table), length(widths) == ncol(table))
  colgroup <- paste0(
    "<col style=\"width:", widths, "%\">",
    collapse = ""
  )
  header <- paste0(
    "<th>", stepwise_html_escape(headers), "</th>",
    collapse = ""
  )
  rows <- vapply(seq_len(nrow(table)), function(i) {
    cells <- vapply(seq_len(ncol(table)), function(j) {
      class <- if (j == 1L && nzchar(first_column_class)) {
        paste0(" class=\"", first_column_class, "\"")
      } else {
        ""
      }
      paste0(
        "<td", class, ">",
        stepwise_scientific_html(table[[j]][[i]]),
        "</td>"
      )
    }, character(1))
    paste0("<tr>", paste(cells, collapse = ""), "</tr>")
  }, character(1))
  paste0(
    "<table id=\"", id, "\"><colgroup>", colgroup, "</colgroup>",
    "<thead><tr>", header, "</tr></thead><tbody>",
    paste(rows, collapse = ""), "</tbody></table>"
  )
}

stepwise_named_table_latex <- function(table, headers, widths, caption, label,
                                       first_column_bold = FALSE) {
  stopifnot(length(headers) == ncol(table), length(widths) == ncol(table))
  columns <- paste0(
    "@{}",
    paste0(
      ">{\\raggedright\\arraybackslash}p{", widths, "\\linewidth}",
      collapse = ""
    ),
    "@{}"
  )
  rows <- vapply(seq_len(nrow(table)), function(i) {
    values <- vapply(seq_len(ncol(table)), function(j) {
      value <- stepwise_latex_escape(table[[j]][[i]])
      if (j == 1L && first_column_bold) paste0("\\textbf{", value, "}") else value
    }, character(1))
    paste0(paste(values, collapse = " & "), " \\\\")
  }, character(1))
  header <- paste(stepwise_latex_escape(headers), collapse = " & ")
  paste0(
    "% Requires \\usepackage{booktabs,longtable,array}\n",
    "\\begingroup\n\\small\n\\setlength{\\tabcolsep}{4pt}\n",
    "\\renewcommand{\\arraystretch}{1.08}\n",
    "\\setlength{\\LTcapwidth}{\\linewidth}\n",
    "\\begin{longtable}{", columns, "}\n",
    "\\caption{", stepwise_latex_escape(caption), "}",
    "\\label{", label, "}\\\\\n",
    "\\toprule\n", header, " \\\\\n\\midrule\n\\endfirsthead\n",
    "\\toprule\n", header, " \\\\\n\\midrule\n\\endhead\n",
    paste(rows, collapse = "\n"),
    "\n\\bottomrule\n\\end{longtable}\n\\endgroup\n"
  )
}

stepwise_render_result_bundle <- function(discovered, output_dir) {
  payloads <- discovered$payload[nzchar(discovered$payload)]
  if (!length(payloads)) return("")
  folders <- unique(dirname(payloads))
  result_dir <- file.path(output_dir, "model-results")
  tryCatch({
    mfclshiny::build_report_figures(
      folders = folders,
      output_dir = result_dir,
      title = "BET 2026 stepwise fitted-model results",
      figure_basename = "bet-2026-stepwise",
      formats = "png",
      build_payloads = FALSE,
      report_tables = TRUE,
      render_html = TRUE,
      html_file = "stepwise-model-results.html",
      optimize_figures = TRUE,
      species_code = "BET",
      species_label = "bigeye tuna",
      assessment_year = "2026"
    )
    html_file <- file.path(result_dir, "stepwise-model-results.html")
    if (file.exists(html_file)) paste(readLines(html_file, warn = FALSE), collapse = "\n") else ""
  }, error = function(e) {
    warning("Fitted-model result bundle was not generated: ", conditionMessage(e))
    ""
  })
}

build_stepwise_report <- function(
    config_path = "job-config.R",
    output_dir = Sys.getenv("OUTPUT_DIR", "model-development"),
    input_dir = Sys.getenv("INPUT_DIR", "inputs"),
    job_map_value = Sys.getenv("STEPWISE_MODEL_JOBS", "")) {
  if (!requireNamespace("mfclshiny", quietly = TRUE)) {
    stop("The mfclshiny package is required to build the report.")
  }
  if (!exists("build_stepwise_dag", mode = "function")) {
    source(file.path(dirname(normalizePath(config_path)), "R", "build_stepwise_dag.R"))
  }

  config <- new.env(parent = baseenv())
  sys.source(normalizePath(config_path, mustWork = TRUE), envir = config)
  nodes <- get("stepwise_models", envir = config, inherits = FALSE)
  job_map <- stepwise_parse_job_map(job_map_value)
  unknown <- setdiff(job_map$step_id, nodes$step_id)
  if (length(unknown)) {
    stop("Unknown step identifiers in STEPWISE_MODEL_JOBS: ", paste(unknown, collapse = ", "))
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  pathway_dir <- file.path(output_dir, "pathway")
  pathway_basename <- "bet-2026-stepwise-pathway"
  dag <- build_stepwise_dag(
    config_path = config_path,
    output_dir = pathway_dir,
    basename = pathway_basename
  )
  dag_png <- file.path(pathway_dir, "figures", paste0(pathway_basename, ".png"))
  png_data <- jsonlite::base64_enc(readBin(dag_png, "raw", n = file.info(dag_png)$size))

  table <- stepwise_stage_table(nodes, job_map)
  include_jobs <- nrow(job_map) > 0L
  table_html <- stepwise_table_html(table, include_jobs)
  table_latex <- stepwise_table_latex(table, include_jobs)
  dm_configuration_caption <- paste0(
    "Dirichlet-multinomial configuration used for length-composition weighting ",
    "in the BET 2026 diagnostic model."
  )
  dm_groups_caption <- paste0(
    "Eight fishery groups used to estimate group-specific Dirichlet-multinomial ",
    "overdispersion. Fishery numbers and series names follow the five-region, ",
    "33-fishery input specification."
  )
  dm_configuration_html <- stepwise_named_table_html(
    stepwise_dm_configuration,
    id = "dm-configuration-table",
    headers = c("Component", "Diagnostic-model setting", "Rationale"),
    widths = c(18, 37, 45),
    first_column_class = "row-label"
  )
  dm_groups_html <- stepwise_named_table_html(
    stepwise_dm_groups,
    id = "dm-groups-table",
    headers = c("DM group", "Fishery numbers", "Fishery series", "Grouping basis"),
    widths = c(9, 19, 45, 27),
    first_column_class = "step-number"
  )
  dm_configuration_latex <- stepwise_named_table_latex(
    stepwise_dm_configuration,
    headers = c("Component", "Diagnostic-model setting", "Rationale"),
    widths = c(0.17, 0.36, 0.42),
    caption = dm_configuration_caption,
    label = "tab:bet-dm-configuration",
    first_column_bold = TRUE
  )
  dm_groups_latex <- stepwise_named_table_latex(
    stepwise_dm_groups,
    headers = c("DM group", "Fishery numbers", "Fishery series", "Grouping basis"),
    widths = c(0.075, 0.165, 0.445, 0.245),
    caption = dm_groups_caption,
    label = "tab:bet-dm-groups",
    first_column_bold = TRUE
  )
  dm_configuration_latex <- gsub(
    "Nmax", "$N_{\\max}$", dm_configuration_latex, fixed = TRUE
  )
  discovered <- stepwise_discover_results(job_map, input_dir)
  result_bundle <- stepwise_render_result_bundle(discovered, output_dir)

  method_text <- paste0(
    "Development of the BET 2026 assessment model proceeded sequentially. At each step, one ",
    "model component or data treatment was modified, while all other settings were held ",
    "constant where practicable (Figure XX; Table XX). Configurations retained after evaluation ",
    "defined the main development pathway; side branches document alternatives that were tested ",
    "but not carried forward. The final model used a Dirichlet-multinomial (DM) likelihood for ",
    "length-composition data. The DM configuration and its eight fishery groupings are ",
    "summarised in Tables XX and XX, respectively."
  )
  method_latex <- gsub(
    "Figure XX; Table XX", "Figure~XX; Table~XX", method_text, fixed = TRUE
  )
  method_latex <- gsub(
    "Tables XX and XX", "Tables~XX and~XX", method_latex, fixed = TRUE
  )
  figure_caption <- paste0(
    "Stepwise model-development pathway for the BET 2026 assessment. Solid teal arrows ",
    "show configurations carried forward; dashed orange arrows show comparison branches. ",
    "The dark-teal node marks the final model."
  )
  table_caption <- paste0(
    "Changes evaluated during stepwise development of the BET 2026 assessment and their ",
    "rationale. Step numbers correspond to the pathway in Figure XX."
  )
  dm_section <- paste0(
    "<section class=\"model-card\"><h2>Diagnostic-model Dirichlet-multinomial configuration</h2>",
    "<p>The diagnostic model used a Dirichlet-multinomial likelihood for length compositions. ",
    "The 33 fisheries were pooled into eight groups, with dispersion estimated by group. ",
    paste0(
      "An effective-sample-size upper bound of 25 was set using composition-level ",
      "effective sample sizes from the Francis reweighting as an empirical reference.</p>"
    ),
    "<div class=\"format-block\"><p class=\"caption\" id=\"dm-configuration-caption\"><strong>Table ",
    "<span contenteditable=\"true\">XX</span>.</strong> ",
    stepwise_html_escape(dm_configuration_caption), "</p>",
    "<div class=\"table-shell\">", dm_configuration_html, "</div>",
    "<div class=\"actions\"><button onclick=\"copyReportTable('dm-configuration-caption','dm-configuration-table',this)\">",
    "Copy table + caption for Word</button>",
    "<button class=\"secondary\" onclick=\"copyText('dm-configuration-latex',this)\">",
    "Copy table + caption for LaTeX</button></div></div>",
    "<div class=\"format-block dm-groups-block\"><p class=\"caption\" id=\"dm-groups-caption\"><strong>Table ",
    "<span contenteditable=\"true\">XX</span>.</strong> ",
    stepwise_html_escape(dm_groups_caption), "</p>",
    "<div class=\"table-shell\">", dm_groups_html, "</div>",
    "<div class=\"actions\"><button onclick=\"copyReportTable('dm-groups-caption','dm-groups-table',this)\">",
    "Copy table + caption for Word</button>",
    "<button class=\"secondary\" onclick=\"copyText('dm-groups-latex',this)\">",
    "Copy table + caption for LaTeX</button></div></div></section>"
  )

  result_section <- ""
  if (nrow(discovered)) {
    result_rows <- paste0(
      "<tr><td>", stepwise_html_escape(discovered$step_id), "</td><td>#",
      discovered$job_number, "</td><td>", stepwise_html_escape(discovered$status), "</td></tr>",
      collapse = ""
    )
    iframe <- if (nzchar(result_bundle)) {
      paste0(
        "<iframe class=\"results-frame\" title=\"Fitted-model figures and tables\" srcdoc=\"",
        stepwise_html_escape(result_bundle), "\"></iframe>"
      )
    } else {
      "<p class=\"note\">Fitted-model figures will appear when mapped job outputs contain model payloads.</p>"
    }
    result_section <- paste0(
      "<section class=\"model-card\"><h2>Fitted-model results</h2>",
      "<p>Results are included only for explicitly mapped completed jobs.</p>",
      "<table class=\"compact\"><thead><tr><th>Step</th><th>Job</th><th>Status</th></tr></thead><tbody>",
      result_rows, "</tbody></table>", iframe, "</section>"
    )
  }

  latex_figure <- paste0(
    "\\begin{figure}[htbp]\n\\centering\n",
    "\\includegraphics[width=\\linewidth,height=0.80\\textheight,keepaspectratio]{pathway/figures/bet-2026-stepwise-pathway.png}\n",
    "\\caption{", stepwise_latex_escape(figure_caption), "}\n",
    "\\label{fig:bet-stepwise-pathway}\n\\end{figure}\n"
  )

  html_file <- file.path(output_dir, "bet-2026-stepwise-model-development.html")
  html <- paste0(
    "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">",
    "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">",
    "<title>BET 2026 model development</title><style>",
    ":root{--ink:#123b5d;--muted:#526979;--sea:#087f8c;--paper:#f5f1e8;--card:#fff;--line:#c8d9df;--orange:#d97904}",
    "*{box-sizing:border-box}body{margin:0;background:#eef2f3;color:#1d2f3a;font-family:\"Aptos\",\"Source Sans 3\",sans-serif;",
    "font-size:16px;line-height:1.55}header{padding:32px max(5vw,24px) 28px;background:var(--ink);color:#fff}",
    "header .eyebrow{font-size:.72rem;letter-spacing:.18em;font-weight:800;text-transform:uppercase}header h1{font-family:Georgia,\"Times New Roman\",serif;",
    "font-size:clamp(2rem,4vw,3.35rem);line-height:1.08;margin:.35rem 0 .7rem}header p{max-width:850px;margin:0;color:#d6edf1;font-size:1.02rem}",
    "main{max-width:1420px;margin:auto;padding:28px max(3vw,18px) 70px}.overview,.model-card{background:var(--card);border:1px solid var(--line);",
    "padding:clamp(20px,3vw,38px);margin-bottom:28px}.overview{border-top:5px solid var(--orange)}.model-card{border-top:5px solid var(--sea)}",
    "h2{font-family:Georgia,\"Times New Roman\",serif;color:var(--ink);font-size:clamp(1.5rem,2.5vw,2.15rem);margin:.2rem 0 1rem}",
    "p{max-width:1080px}.format-block{margin-top:32px;padding-top:25px;border-top:1px solid var(--line)}.figure-shell{overflow:auto;border:1px solid var(--line);",
    "background:#fff;padding:6px}.dag-figure{display:block;width:100%;height:auto;max-width:100%;margin:0 auto}",
    "figcaption,.caption{margin-top:12px;padding:12px 15px;background:#f1f6f7;border-left:3px solid var(--sea);color:#29495b;",
    "font-family:Georgia,\"Times New Roman\",serif;font-size:.95rem;line-height:1.55}figcaption::before{content:\"Caption\";display:block;",
    "margin-bottom:4px;color:var(--ink);font-family:\"Aptos\",\"Source Sans 3\",sans-serif;font-size:.7rem;font-weight:800;",
    "letter-spacing:.12em;text-transform:uppercase}.actions{display:flex;gap:9px;flex-wrap:wrap;margin:18px 0 8px}button,a.button{border:0;",
    "background:var(--sea);color:#fff;padding:9px 14px;font-weight:700;cursor:pointer;transition:background .16s ease;text-decoration:none}",
    "button:hover,a.button:hover{background:var(--ink)}button.secondary{background:#fff;color:var(--sea);border:1px solid var(--sea)}",
    "button.done{background:#24784f}.table-shell{width:100%;overflow:auto;max-height:950px;border:1px solid var(--line);margin:14px 0 18px}",
    "table{width:100%;border-collapse:collapse;font-size:.89rem;table-layout:fixed}th{position:sticky;top:0;z-index:1;background:var(--ink);color:#fff;text-align:left;",
    "padding:10px 12px;line-height:1.25}td{vertical-align:top;padding:11px 12px;border-bottom:1px solid #dce7ea;",
    "overflow-wrap:anywhere;word-break:normal;hyphens:auto}.step-number{font-weight:800;color:var(--ink);text-align:center;white-space:nowrap}",
    ".job{font-weight:700;white-space:nowrap}",
    ".table-reference{max-width:none;margin:0;color:var(--muted);font-size:.9rem;line-height:1.5}",
    ".row-label{font-weight:750;color:var(--ink)}",
    ".table-reference ol{margin:.6rem 0 0;padding-left:1.35rem}.table-reference li{margin:.45rem 0}",
    ".table-reference a{color:var(--ink);text-decoration-color:var(--sea);text-underline-offset:2px}",
    ".note{padding:13px 16px;border-left:4px solid var(--sea);",
    "background:#eff5f5;color:#3a5967}.hidden-copy{display:none}.results-frame{width:100%;height:1100px;",
    "border:1px solid var(--line);background:#fff}.compact{max-width:700px}.action-status{position:fixed;right:22px;bottom:22px;z-index:20;",
    "background:var(--ink);color:#fff;padding:10px 15px;box-shadow:0 8px 24px rgba(18,59,93,.2);opacity:0;transform:translateY(8px);",
    "pointer-events:none;transition:opacity .16s ease,transform .16s ease}.action-status.show{opacity:1;transform:translateY(0)}",
    "@media(max-width:760px){main{padding:18px 10px 45px}table{font-size:.82rem;min-width:700px}}@page{size:A4;margin:14mm}@media print{body{background:#fff}",
    "header{padding:0 0 20px;background:#fff;color:var(--ink)}header p{color:var(--muted)}main{max-width:none;padding:0}.overview,.model-card{border:0;padding:0;margin:0}",
    "button,.actions,.action-status{display:none}h2{break-after:avoid}figure{break-inside:avoid}thead{display:table-header-group}",
    "tr{break-inside:avoid}.table-shell{overflow:visible;max-height:none}.model-card{break-before:page}.dm-groups-block{break-before:page}",
    "#dm-groups-table{font-size:.78rem}#dm-groups-table th,#dm-groups-table td{padding:6px 8px;line-height:1.25}}",
    "</style></head><body><header><div class=\"eyebrow\">BET 2026 assessment</div><h1>Stepwise model development</h1>",
    "<p>Assessment pathway and rationale</p></header><main>",
    "<section class=\"overview\"><h2>Model-development approach</h2><p id=\"method-text\">", stepwise_html_escape(method_text), "</p>",
    "<div class=\"actions\"><button onclick=\"copyHtml('method-text',this)\">Copy analysis for Word</button>",
    "<button class=\"secondary\" onclick=\"copyText('method-latex',this)\">Copy analysis for LaTeX</button></div>",
    "<div class=\"format-block\"><h2>Model pathway</h2><figure><div class=\"figure-shell\"><img class=\"dag-figure\" alt=\"BET 2026 stepwise model-development pathway\" src=\"data:image/png;base64,", png_data, "\">",
    "</div><figcaption id=\"figure-caption\"><strong>Figure <span contenteditable=\"true\">XX</span>.</strong> ",
    stepwise_html_escape(figure_caption), "</figcaption></figure>",
    "<div class=\"actions\"><button onclick=\"copyFigure(this)\">Copy figure + caption for Word</button>",
    "<a class=\"button\" download href=\"data:image/png;base64,", png_data, "\">Save PNG</a>",
    "<button class=\"secondary\" onclick=\"copyText('figure-latex',this)\">Copy figure + caption for LaTeX</button></div></div>",
    "<div class=\"format-block\"><h2>Stepwise changes</h2><p class=\"caption\" id=\"table-caption\"><strong>Table ",
    "<span contenteditable=\"true\">XX</span>.</strong> ", stepwise_html_escape(table_caption), "</p>",
    "<div class=\"table-shell\">", table_html, "</div><div class=\"actions\"><button onclick=\"copyTable(this)\">Copy table + caption for Word</button>",
    "<button class=\"secondary\" onclick=\"copyText('table-latex',this)\">Copy table + caption for LaTeX</button></div></div></section>",
    dm_section,
    result_section,
    "<section class=\"model-card\"><div id=\"references-word\"><h2>References</h2><div class=\"table-reference\" id=\"table-reference\"><ol><li>",
    paste0(
      "<a href=\"", stepwise_html_escape(stepwise_reference_urls), "\">",
      stepwise_html_escape(stepwise_references), "</a>",
      collapse = "</li><li>"
    ),
    "</li></ol></div></div><div class=\"actions\"><button onclick=\"copyHtml('references-word',this)\">Copy references for Word</button>",
    "<button class=\"secondary\" onclick=\"copyText('references-bibtex',this)\">Copy BibTeX</button>",
    "<a class=\"button\" download href=\"stepwise-references.bib\">Download .bib</a></div></section>",
    "<pre id=\"method-latex\" class=\"hidden-copy\">", stepwise_html_escape(method_latex), "</pre>",
    "<pre id=\"figure-latex\" class=\"hidden-copy\">", stepwise_html_escape(latex_figure), "</pre>",
    "<pre id=\"table-latex\" class=\"hidden-copy\">", stepwise_html_escape(table_latex), "</pre>",
    "<pre id=\"dm-configuration-latex\" class=\"hidden-copy\">", stepwise_html_escape(dm_configuration_latex), "</pre>",
    "<pre id=\"dm-groups-latex\" class=\"hidden-copy\">", stepwise_html_escape(dm_groups_latex), "</pre>",
    "<pre id=\"references-bibtex\" class=\"hidden-copy\">", stepwise_html_escape(stepwise_references_bibtex), "</pre>",
    "<img id=\"dag-png\" hidden src=\"data:image/png;base64,", png_data, "\">",
    "<div id=\"action-status\" class=\"action-status\" role=\"status\" aria-live=\"polite\"></div>",
    "<script>",
    "function feedback(b,t){const s=document.getElementById('action-status');s.textContent=t;s.classList.add('show');",
    "if(b){b.classList.add('done')}setTimeout(()=>{s.classList.remove('show');if(b){b.classList.remove('done')}},1400)}",
    "async function copyText(id,b){try{await navigator.clipboard.writeText(document.getElementById(id).textContent);feedback(b,'Copied')}",
    "catch(e){feedback(b,'Copy failed')}}",
    "async function writeClipboard(html,text,b){try{await navigator.clipboard.write([new ClipboardItem({'text/html':new Blob([html],{type:'text/html'}),",
    "'text/plain':new Blob([text],{type:'text/plain'})})]);feedback(b,'Copied')}catch(e){try{await navigator.clipboard.writeText(text);",
    "feedback(b,'Copied as text')}catch(x){feedback(b,'Copy failed')}}}",
    "function copyHtml(id,b){const e=document.getElementById(id);writeClipboard(e.outerHTML,e.innerText,b)}",
    "function copyTable(b){const c=document.getElementById('table-caption'),t=document.getElementById('stage-table'),r=document.getElementById('table-reference'),x=t.cloneNode(true);",
    "x.style.cssText='width:100%;border-collapse:collapse;table-layout:fixed;font-family:Cambria,Georgia,serif;font-size:10pt;line-height:1.25';",
    "x.querySelectorAll('th').forEach(e=>e.style.cssText='background:#e8f1f1;text-align:left;border-top:1.5pt solid #173042;border-bottom:0.8pt solid #173042;padding:6pt;vertical-align:top');",
    "x.querySelectorAll('td').forEach(e=>e.style.cssText='border-bottom:0.5pt solid #d7e0e3;padding:6pt;vertical-align:top;overflow-wrap:anywhere');",
    "const cap='<p style=\"font-family:Cambria,Georgia,serif;font-size:10pt;line-height:1.25;margin:0 0 6pt\">'+c.innerHTML+'</p>';",
    "writeClipboard(cap+x.outerHTML+r.outerHTML,c.innerText+'\\n'+t.innerText+'\\n'+r.innerText,b)}",
    "function copyReportTable(captionId,tableId,b){const c=document.getElementById(captionId),t=document.getElementById(tableId),x=t.cloneNode(true);",
    "x.style.cssText='width:100%;border-collapse:collapse;table-layout:fixed;font-family:Cambria,Georgia,serif;font-size:10pt;line-height:1.25';",
    "x.querySelectorAll('th').forEach(e=>e.style.cssText='background:#e8f1f1;text-align:left;border-top:1.5pt solid #173042;border-bottom:0.8pt solid #173042;padding:6pt;vertical-align:top');",
    "x.querySelectorAll('td').forEach(e=>e.style.cssText='border-bottom:0.5pt solid #d7e0e3;padding:6pt;vertical-align:top;overflow-wrap:anywhere');",
    "const cap='<p style=\"font-family:Cambria,Georgia,serif;font-size:10pt;line-height:1.25;margin:0 0 6pt\">'+c.innerHTML+'</p>';",
    "writeClipboard(cap+x.outerHTML,c.innerText+'\\n'+t.innerText,b)}",
    "function copyFigure(b){const i=document.getElementById('dag-png'),c=document.getElementById('figure-caption');",
    "writeClipboard('<figure><img src=\"'+i.src+'\" style=\"max-width:100%;height:auto\"><figcaption>'+c.innerHTML+'</figcaption></figure>',",
    "c.innerText,b)}",
    "</script></main></body></html>"
  )
  writeLines(html, html_file, useBytes = TRUE)
  export_columns <- c("step", "change", "rationale")
  if (include_jobs) export_columns <- c(export_columns, "job_number")
  export_table <- table[export_columns]
  write.csv(
    export_table,
    file.path(output_dir, "stepwise-model-configurations.csv"),
    row.names = FALSE
  )
  writeLines(table_latex, file.path(output_dir, "stepwise-model-configurations.tex"))
  write.csv(
    stepwise_dm_configuration,
    file.path(output_dir, "stepwise-dm-configuration.csv"),
    row.names = FALSE
  )
  write.csv(
    stepwise_dm_groups,
    file.path(output_dir, "stepwise-dm-groups.csv"),
    row.names = FALSE
  )
  writeLines(
    dm_configuration_latex,
    file.path(output_dir, "stepwise-dm-configuration.tex")
  )
  writeLines(dm_groups_latex, file.path(output_dir, "stepwise-dm-groups.tex"))
  writeLines(stepwise_references_bibtex, file.path(output_dir, "stepwise-references.bib"))
  writeLines(paste0("Figure XX. ", figure_caption), file.path(output_dir, "stepwise-pathway-caption.txt"))
  writeLines(
    c(
      paste0("Table XX. ", table_caption),
      paste0("Table XX. ", dm_configuration_caption),
      paste0("Table XX. ", dm_groups_caption),
      "References.",
      stepwise_references
    ),
    file.path(output_dir, "stepwise-table-caption.txt")
  )

  invisible(list(
    html = html_file,
    pathway = dag,
    configurations = file.path(output_dir, "stepwise-model-configurations.csv"),
    dm_configuration = file.path(output_dir, "stepwise-dm-configuration.csv"),
    dm_groups = file.path(output_dir, "stepwise-dm-groups.csv"),
    references = file.path(output_dir, "stepwise-references.bib"),
    discovered_results = discovered
  ))
}

`%||%` <- function(x, y) if (is.null(x) || !length(x) || is.na(x[[1L]])) y else x

if (sys.nframe() == 0L) {
  build_stepwise_report()
}
