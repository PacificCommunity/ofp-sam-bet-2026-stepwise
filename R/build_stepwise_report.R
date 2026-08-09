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

stepwise_viewer_release_url <- paste0(
  "https://pacificcommunity.github.io/",
  "ofp-sam-bet-2026-stepwise/interactive-model-viewer.html"
)

stepwise_data_uri <- function(file, mime) {
  if (!file.exists(file)) return("")
  paste0(
    "data:", mime, ";base64,",
    jsonlite::base64_enc(readBin(file, "raw", n = file.info(file)$size))
  )
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
    "Scutt Phillips, J., Senina, I. and Bonin, L. (2026). Estimation of tag ",
    "mixing periods for the 2026 WCPO tuna stock assessments. ",
    "WCPFC-SC22-2026-SA-IP10."
  ),
  paste0(
    "Lorenzen, K. (1996). The relationship between body weight and natural ",
    "mortality in juvenile and adult fish: a comparison of natural ecosystems ",
    "and aquaculture. Journal of Fish Biology, 49, 627-642. ",
    "doi:10.1111/j.1095-8649.1996.tb00060.x."
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
  "https://meetings.wcpfc.int/node/32243",
  "https://doi.org/10.1111/j.1095-8649.1996.tb00060.x",
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
  "@techreport{ScuttPhillipsEtAl2026TagMixing,\n",
  "  author = {Scutt Phillips, J. and Senina, I. and Bonin, L.},\n",
  "  title = {Estimation of tag mixing periods for the 2026 WCPO tuna stock assessments},\n",
  "  institution = {Western and Central Pacific Fisheries Commission},\n",
  "  number = {WCPFC-SC22-2026-SA-IP10},\n",
  "  url = {https://meetings.wcpfc.int/node/32243},\n",
  "  year = {2026}\n",
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
      "STEPWISE_MODEL_JOBS must use comma-separated step=job pairs.",
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
    model = trimws(as.character(nodes$model_label)),
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
      "<col style=\"width:6%\"><col style=\"width:18%\">",
      "<col style=\"width:29%\"><col style=\"width:41%\"><col style=\"width:6%\">"
    )
  } else {
    paste0(
      "<col style=\"width:7%\"><col style=\"width:21%\">",
      "<col style=\"width:31%\"><col style=\"width:41%\">"
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
      "<td class=\"row-label\">", stepwise_html_escape(table$model[[i]]), "</td>",
      "<td>", stepwise_html_escape(table$change[[i]]), "</td>",
      "<td>", stepwise_html_escape(rationale), "</td>", job_cell, "</tr>"
    )
  }, character(1))
  paste0(
    "<table id=\"stage-table\"><colgroup>", colgroup, "</colgroup>",
    "<thead><tr><th>Step</th><th>Configuration</th><th>What changed</th>",
    "<th>Why it was evaluated</th>", job_header,
    "</tr></thead><tbody>", paste(rows, collapse = ""), "</tbody></table>"
  )
}

stepwise_table_latex <- function(table, include_jobs = FALSE) {
  columns <- if (include_jobs) {
    paste0(
      "@{}>{\\centering\\arraybackslash}p{0.05\\linewidth}",
      ">{\\raggedright\\arraybackslash}p{0.17\\linewidth}",
      ">{\\raggedright\\arraybackslash}p{0.27\\linewidth}",
      ">{\\raggedright\\arraybackslash}p{0.39\\linewidth}r@{}"
    )
  } else {
    paste0(
      "@{}>{\\centering\\arraybackslash}p{0.05\\linewidth}",
      ">{\\raggedright\\arraybackslash}p{0.20\\linewidth}",
      ">{\\raggedright\\arraybackslash}p{0.29\\linewidth}",
      ">{\\raggedright\\arraybackslash}p{0.40\\linewidth}@{}"
    )
  }
  header <- if (include_jobs) {
    "Step & Configuration & What changed & Why it was evaluated & Job"
  } else {
    "Step & Configuration & What changed & Why it was evaluated"
  }
  rows <- vapply(seq_len(nrow(table)), function(i) {
    values <- c(
      paste0("\\textbf{", stepwise_latex_escape(table$step[[i]]), "}"),
      stepwise_latex_escape(table$model[[i]]),
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

stepwise_report_table_latex <- function(table, headers, widths, caption, label) {
  stopifnot(length(headers) == ncol(table), length(widths) == ncol(table))
  # Leave space for inter-column padding inside an A4 landscape text block.
  # Raw p-column fractions that sum to one overflow once tabular padding is
  # added, even though the table appears visually close to the page width.
  widths <- widths / sum(widths) * 0.92
  columns <- paste0(
    "@{}",
    paste0(
      ">{\\raggedright\\arraybackslash}p{", widths, "\\linewidth}",
      collapse = ""
    ),
    "@{}"
  )
  format_cell <- function(value) {
    if (!length(value) || is.na(value[[1L]]) || !nzchar(trimws(as.character(value[[1L]])))) return("")
    if (is.numeric(value)) return(format(value[[1L]], digits = 7, trim = TRUE, scientific = FALSE))
    as.character(value[[1L]])
  }
  rows <- vapply(seq_len(nrow(table)), function(i) {
    values <- vapply(table[i, , drop = FALSE], format_cell, character(1))
    values <- stepwise_latex_escape(values)
    values[[1L]] <- paste0("\\textbf{", values[[1L]], "}")
    paste0(paste(values, collapse = " & "), " \\\\")
  }, character(1))
  paste0(
    "% Requires \\usepackage{booktabs,longtable,array,pdflscape}\n",
    "\\begin{landscape}\n\\begingroup\n\\scriptsize\n",
    "\\setlength{\\tabcolsep}{2pt}\n\\renewcommand{\\arraystretch}{1.08}\n",
    "\\setlength{\\LTcapwidth}{\\linewidth}\n",
    "\\begin{longtable}{", columns, "}\n",
    "\\caption{", stepwise_latex_escape(caption), "}",
    "\\label{", label, "}\\\\\n",
    "\\toprule\n", paste(stepwise_latex_escape(headers), collapse = " & "),
    " \\\\\n\\midrule\n\\endfirsthead\n",
    "\\toprule\n", paste(stepwise_latex_escape(headers), collapse = " & "),
    " \\\\\n\\midrule\n\\endhead\n",
    paste(rows, collapse = "\n"),
    "\n\\bottomrule\n\\end{longtable}\n\\endgroup\n\\end{landscape}\n"
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
  if (!exists("build_stepwise_dag", mode = "function")) {
    source(file.path(dirname(normalizePath(config_path)), "R", "build_stepwise_dag.R"))
  }
  if (!exists("stepwise_prepare_result_assets", mode = "function")) {
    source(file.path(dirname(normalizePath(config_path)), "R", "stepwise_report_inputs.R"))
  }
  if (!exists("build_stepwise_key_quantities", mode = "function")) {
    source(file.path(dirname(normalizePath(config_path)), "R", "build_stepwise_key_quantities.R"))
  }

  config <- new.env(parent = baseenv())
  sys.source(normalizePath(config_path, mustWork = TRUE), envir = config)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  source_index <- stepwise_json_records(Sys.getenv("STEPWISE_SOURCE_INDEX_JSON", ""))
  if (!nrow(source_index)) {
    source_index <- stepwise_repository_source_index(input_dir)
  }
  assets <- stepwise_prepare_result_assets(input_dir, output_dir, source_index)
  key_assets <- build_stepwise_key_quantities(assets$result_dir, source_index)
  assets$figure_index <- key_assets$figure_index
  assets$table_index <- key_assets$table_index
  if (!nrow(source_index)) {
    source_index <- stepwise_source_index_from_viewer(assets$viewer_data)
  }

  configured <- get("stepwise_models", envir = config, inherits = FALSE)
  explicit_map <- stepwise_parse_job_map(job_map_value)
  if (!nrow(source_index) && nrow(explicit_map)) {
    source_index <- data.frame(
      order = seq_len(nrow(explicit_map)),
      row = sub("-.*$", "", explicit_map$step_id),
      step_id = explicit_map$step_id,
      job_number = explicit_map$job_number,
      job_title = explicit_map$step_id,
      model_label = explicit_map$step_id,
      change_axis = explicit_map$step_id,
      scientific_parent_id = c("", head(explicit_map$step_id, -1L)),
      selected = TRUE,
      task = "",
      status = "",
      stringsAsFactors = FALSE
    )
  }
  if (!nrow(source_index)) {
    stop(
      "No dynamic model index was found. Supply a viewer job through the submission helper ",
      "or stage model payload inputs.", call. = FALSE
    )
  }

  matches <- match(source_index$step_id, configured$step_id)
  nodes <- configured[matches, , drop = FALSE]
  unknown <- is.na(matches)
  if (any(unknown)) {
    for (name in names(nodes)) nodes[[name]][unknown] <- NA
  }
  nodes$step_id <- source_index$step_id
  dynamic_labels <- trimws(as.character(source_index$model_label))
  missing_label <- is.na(dynamic_labels) | !nzchar(dynamic_labels)
  dynamic_labels[missing_label] <- trimws(as.character(source_index$job_title[missing_label]))
  missing_label <- is.na(dynamic_labels) | !nzchar(dynamic_labels)
  dynamic_labels[missing_label] <- source_index$step_id[missing_label]
  nodes$model_label <- dynamic_labels
  dynamic_parent <- trimws(as.character(source_index$scientific_parent_id))
  use_parent <- !is.na(dynamic_parent) & nzchar(dynamic_parent)
  nodes$scientific_parent_id[use_parent] <- dynamic_parent[use_parent]
  nodes$selected <- source_index$selected
  configured_purpose <- configured$report_purpose[matches]
  configured_purpose <- gsub(
    "Job[[:space:]]+[0-9]+(/[0-9]+)?",
    "selected reference configuration",
    configured_purpose,
    perl = TRUE
  )
  fallback_purpose <- stepwise_sentence(source_index$change_axis)
  missing_purpose <- is.na(configured_purpose) | !nzchar(trimws(configured_purpose))
  configured_purpose[missing_purpose] <- fallback_purpose[missing_purpose]
  nodes$report_purpose <- configured_purpose
  configured_change <- configured$report_change[matches]
  configured_change <- gsub(
    "Job[[:space:]]+[0-9]+(/[0-9]+)?",
    "selected fitted configuration",
    configured_change,
    perl = TRUE
  )
  missing_change <- is.na(configured_change) | !nzchar(trimws(configured_change))
  configured_change[missing_change] <- fallback_purpose[missing_change]
  nodes$report_change <- configured_change
  job_map <- source_index[, c("step_id", "job_number"), drop = FALSE]

  pathway_dir <- file.path(output_dir, "pathway")
  pathway_basename <- "bet-2026-stepwise-pathway"
  dag <- build_stepwise_dag(
    config_path = config_path,
    output_dir = pathway_dir,
    basename = pathway_basename,
    models = nodes
  )
  dag_png <- file.path(pathway_dir, "figures", paste0(pathway_basename, ".png"))
  png_data <- jsonlite::base64_enc(readBin(dag_png, "raw", n = file.info(dag_png)$size))

  table <- stepwise_stage_table(nodes, job_map)
  # Job provenance remains available in the runtime inventory. The main
  # paper/report table is kept scientific and compact for A4 reproduction.
  include_jobs <- FALSE
  table_html <- stepwise_table_html(table, include_jobs)
  table_latex <- stepwise_table_latex(table, include_jobs)
  discovered <- stepwise_discover_payload_index(input_dir, source_index)

  method_text <- paste0(
    "Development of the BET 2026 assessment model proceeded sequentially. At each step, one ",
    "model component or data treatment was modified, while all other settings were held ",
    "constant where practicable, as summarised in the pathway figure and accompanying table. The configurations are presented in ",
    "evaluation order; Step 14a documents the regional CAAL weighting evaluated immediately ",
    "before the Step 14b treatment that was carried forward. Model diagnostics, fitted quantities, figures, and supporting ",
    "tables were reconstructed from the checksum-locked repository payloads."
  )
  method_latex <- method_text
  figure_caption <- paste0(
    "Stepwise model-development pathway for the BET 2026 assessment. Configurations are ",
    "arranged in evaluation order from Step 1 to Step 22. Step 14a was evaluated ",
    "before the Step 14b configuration that was carried forward. The dark-teal row identifies ",
    "the final Diagnostic model."
  )
  table_caption <- paste0(
    "Changes evaluated during stepwise development of the BET 2026 assessment and their ",
    "rationale. Step numbers correspond to the pathway shown above."
  )
  summary_table <- assets$model_summary
  summary_headers <- names(summary_table)
  summary_headers[summary_headers == "Max gradient"] <- "Maximum gradient component (MGC)"
  summary_headers[summary_headers == "Objective value"] <- "Objective function value"
  summary_headers[summary_headers == "Hessian PDH"] <- "PDH"
  names(summary_table) <- summary_headers
  objective_table <- assets$objective_components
  summary_html <- stepwise_dynamic_table_html(summary_table, "dynamic-model-summary")
  objective_html <- stepwise_dynamic_table_html(objective_table, "dynamic-objective-components")
  summary_caption <- paste0(
    "Convergence and native Hessian diagnostics for the configurations evaluated during stepwise development ",
    "of the BET 2026 assessment. PDH denotes a positive-definite Hessian based on native MFCL eigenvalue analysis."
  )
  objective_caption <- paste0(
    "Objective-function and likelihood-component values for the configurations evaluated during stepwise ",
    "development of the BET 2026 assessment. Values are reported on the native MFCL objective scale; the ",
    "composition-likelihood formulation changes at Step 19."
  )
  summary_latex <- stepwise_report_table_latex(
    summary_table, names(summary_table),
    c(0.17, 0.16, 0.15, 0.12, 0.10, 0.13, 0.14),
    summary_caption, "tab:bet-stepwise-fit-diagnostics"
  )
  objective_latex <- stepwise_report_table_latex(
    objective_table, names(objective_table),
    c(0.17, 0.12, 0.10, 0.12, 0.12, 0.09, 0.09, 0.08, 0.09),
    objective_caption, "tab:bet-stepwise-likelihood-components"
  )
  viewer_data_uri <- stepwise_data_uri(assets$viewer, "text/html;charset=utf-8")
  viewer_url <- stepwise_viewer_release_url
  viewer_link <- if (nzchar(assets$viewer)) {
    paste0(
      "<div class=\"viewer-actions\"><a class=\"button\" href=\"", viewer_url, "\" target=\"_blank\" rel=\"noopener\">",
      "Open interactive viewer in browser</a></div>",
      "<iframe class=\"viewer-frame\" loading=\"lazy\" title=\"Interactive stepwise model viewer\" ",
      "src=\"", viewer_data_uri, "\"></iframe>"
    )
  } else {
    "<p class=\"note\">The interactive viewer could not be generated from the supplied inputs.</p>"
  }
  result_section <- paste0(
    "<section class=\"model-card\" id=\"interactive-viewer\"><h2>Interactive model viewer</h2>",
    "<p>The embedded viewer and the GitHub Pages viewer are generated from the same checksum-locked fitted-model payloads.</p>",
    viewer_link, "</section>",
    "<section class=\"model-card\"><h2>Fit diagnostics and likelihood components</h2>",
    "<h3>Fit diagnostics</h3><p class=\"caption\" id=\"fit-caption\"><strong>Table <span contenteditable=\"true\">XX</span>.</strong> ",
    stepwise_html_escape(summary_caption), "</p><div class=\"table-shell\">", summary_html, "</div>",
    "<div class=\"actions\"><button onclick=\"copyReportTable('fit-caption','dynamic-model-summary',this)\">Copy table for Word</button>",
    "<button class=\"secondary\" onclick=\"copyText('fit-latex',this)\">Copy LaTeX</button>",
    "<a class=\"button\" href=\"stepwise-model-summary.csv\" download>Download CSV</a></div>",
    "<h3>Likelihood components</h3><p class=\"caption\" id=\"likelihood-caption\"><strong>Table <span contenteditable=\"true\">XX</span>.</strong> ",
    stepwise_html_escape(objective_caption), "</p><div class=\"table-shell\">", objective_html, "</div>",
    "<div class=\"actions\"><button onclick=\"copyReportTable('likelihood-caption','dynamic-objective-components',this)\">Copy table for Word</button>",
    "<button class=\"secondary\" onclick=\"copyText('likelihood-latex',this)\">Copy LaTeX</button>",
    "<a class=\"button\" href=\"stepwise-objective-components.csv\" download>Download CSV</a></div>",
    "</section>",
    "<section class=\"model-card\"><h2>SC assessment figures</h2>",
    "<p>Priority stock-status, population-dynamics, fit, selectivity, spatial and tagging figures are read from the upstream figure index.</p>",
    stepwise_figure_sections_html(assets$figure_index, output_dir, viewer_url), "</section>",
    "<section class=\"model-card\"><h2>Supporting tables</h2>",
    stepwise_table_downloads_html(assets$table_index), "</section>"
  )

  latex_figure <- paste0(
    "% Requires \\usepackage{graphicx,hyperref}\n",
    "\\begin{figure}[htbp]\n\\centering\n",
    "\\includegraphics[width=\\linewidth,height=0.88\\textheight,keepaspectratio]{pathway/figures/bet-2026-stepwise-pathway.pdf}\n",
    "\\caption{", stepwise_latex_escape(figure_caption), "}\n",
    "\\label{fig:bet-stepwise-pathway}\n",
    "\\par\\small\\href{", viewer_url, "}",
    "{Explore individual model configurations in the interactive viewer.}\n",
    "\\end{figure}\n"
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
    "background:#eff5f5;color:#3a5967}.hidden-copy{display:none}.viewer-actions{display:flex;gap:10px;flex-wrap:wrap;margin:15px 0}",
    ".viewer-actions .alt{background:#fff;color:var(--sea);border:1px solid var(--sea)}.viewer-frame{width:100%;height:860px;",
    "border:1px solid var(--line);background:#fff}.result-grid{display:block}",
    ".result-figure{max-width:1280px;margin:0 auto 30px;border:1px solid var(--line);padding:16px;background:#fff}.result-figure h3{margin:0 0 12px;color:var(--ink)}",
    ".result-figure img{display:block;width:100%;height:auto}.download-list{list-style:none;padding:0}.download-list li{display:grid;grid-template-columns:minmax(220px,32%) 1fr;gap:16px;padding:13px 0;border-bottom:1px solid var(--line)}",
    ".download-list li span{color:var(--muted)}.compact{max-width:700px}.action-status{position:fixed;right:22px;bottom:22px;z-index:20;",
    "background:var(--ink);color:#fff;padding:10px 15px;box-shadow:0 8px 24px rgba(18,59,93,.2);opacity:0;transform:translateY(8px);",
    "pointer-events:none;transition:opacity .16s ease,transform .16s ease}.action-status.show{opacity:1;transform:translateY(0)}",
    "@media(max-width:760px){main{padding:18px 10px 45px}table{font-size:.82rem;min-width:700px}}@page{size:A4;margin:14mm}@media print{body{background:#fff}",
    "header{padding:0 0 20px;background:#fff;color:var(--ink)}header p{color:var(--muted)}main{max-width:none;padding:0}.overview,.model-card{border:0;padding:0;margin:0}",
    "button,.actions,.action-status{display:none}h2{break-after:avoid}figure{break-inside:avoid}thead{display:table-header-group}",
    "tr{break-inside:avoid}.table-shell{overflow:visible;max-height:none}.model-card{break-before:page}.viewer-frame{display:none}",
    ".result-grid{display:block}.result-figure{break-before:page;border:0;padding:0}}",
    "</style></head><body><header><div class=\"eyebrow\">BET 2026 assessment</div><h1>Stepwise model development</h1>",
    "<p>Assessment pathway and rationale</p></header><main>",
    "<section class=\"overview\"><h2>Model-development approach</h2><p id=\"method-text\">", stepwise_html_escape(method_text), "</p>",
    "<div class=\"actions\"><button onclick=\"copyHtml('method-text',this)\">Copy methods text for Word</button>",
    "<button class=\"secondary\" onclick=\"copyText('method-latex',this)\">Copy methods text for LaTeX</button></div>",
    "<div class=\"format-block\"><h2>Model pathway</h2><figure><div class=\"figure-shell\"><a href=\"", viewer_url, "\" target=\"_blank\" rel=\"noopener\" title=\"Open the interactive viewer\"><img class=\"dag-figure\" alt=\"BET 2026 stepwise model-development pathway\" src=\"data:image/png;base64,", png_data, "\"></a>",
    "</div><figcaption id=\"figure-caption\"><strong>Figure.</strong> ",
    stepwise_html_escape(figure_caption), " <a href=\"", viewer_url, "\" target=\"_blank\" rel=\"noopener\">",
    "Explore individual configurations in the interactive viewer.</a></figcaption></figure>",
    "<div class=\"actions\"><button onclick=\"copyFigure(this)\">Copy figure + caption for Word</button>",
    "<a class=\"button\" download href=\"data:image/png;base64,", png_data, "\">Save PNG</a>",
    "<a class=\"button\" download href=\"pathway/figures/bet-2026-stepwise-pathway.pdf\">Save vector PDF</a>",
    "<button class=\"secondary\" onclick=\"copyText('figure-latex',this)\">Copy figure + caption for LaTeX</button></div></div>",
    "<div class=\"format-block\"><h2>Stepwise changes</h2><p class=\"caption\" id=\"table-caption\"><strong>Table.</strong> ",
    stepwise_html_escape(table_caption), "</p>",
    "<div class=\"table-shell\">", table_html, "</div><div class=\"actions\"><button onclick=\"copyTable(this)\">Copy table + caption for Word</button>",
    "<button class=\"secondary\" onclick=\"copyText('table-latex',this)\">Copy table + caption for LaTeX</button></div></div></section>",
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
    "<pre id=\"fit-latex\" class=\"hidden-copy\">", stepwise_html_escape(summary_latex), "</pre>",
    "<pre id=\"likelihood-latex\" class=\"hidden-copy\">", stepwise_html_escape(objective_latex), "</pre>",
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
    "function copyResultFigure(imageId,captionId,b){const i=document.getElementById(imageId),c=document.getElementById(captionId);",
    "writeClipboard('<figure><img src=\"'+i.src+'\" style=\"max-width:100%;height:auto\"><figcaption>'+c.innerHTML+'</figcaption></figure>',",
    "c.innerText,b)}",
    "</script></main></body></html>"
  )
  writeLines(html, html_file, useBytes = TRUE)
  export_columns <- c("step", "model", "change", "rationale")
  if (include_jobs) export_columns <- c(export_columns, "job_number")
  export_table <- table[export_columns]
  write.csv(
    export_table,
    file.path(output_dir, "stepwise-model-configurations.csv"),
    row.names = FALSE
  )
  writeLines(table_latex, file.path(output_dir, "stepwise-model-configurations.tex"))
  writeLines(summary_latex, file.path(output_dir, "stepwise-fit-diagnostics.tex"))
  writeLines(objective_latex, file.path(output_dir, "stepwise-likelihood-components.tex"))
  writeLines(stepwise_references_bibtex, file.path(output_dir, "stepwise-references.bib"))
  writeLines(paste0("Figure. ", figure_caption), file.path(output_dir, "stepwise-pathway-caption.txt"))
  writeLines(
    c(
      paste0("Table. ", table_caption),
      "References.",
      stepwise_references
    ),
    file.path(output_dir, "stepwise-table-caption.txt")
  )

  invisible(list(
    html = html_file,
    pathway = dag,
    configurations = file.path(output_dir, "stepwise-model-configurations.csv"),
    viewer = assets$viewer,
    model_summary = file.path(output_dir, "stepwise-model-summary.csv"),
    objective_components = file.path(output_dir, "stepwise-objective-components.csv"),
    references = file.path(output_dir, "stepwise-references.bib"),
    discovered_results = discovered
  ))
}

`%||%` <- function(x, y) {
  if (is.null(x) || !length(x)) return(y)
  first <- x[[1L]]
  if (length(first) == 1L && is.atomic(first) && is.na(first)) y else x
}

if (sys.nframe() == 0L) {
  build_stepwise_report()
}
