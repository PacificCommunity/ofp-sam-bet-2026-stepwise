# Build a portable, report-ready account of the BET 2026 stepwise pathway.

stepwise_html_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
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
      "01-Diag2023=14047,02a-NewExe1003=14046.",
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

stepwise_settings <- function(row) {
  labels <- c(
    region_count = "Regions",
    age_length_variant = "Age-length weighting",
    tag_flag2 = "Tag flag 2",
    dm_grouping = "DM grouping",
    dm_nmax = "DM Nmax",
    regional_scaling_weight = "Regional-scaling weight",
    reporting_rate_prior = "Reporting-rate setting"
  )
  values <- vapply(names(labels), function(name) {
    value <- row[[name]]
    if (is.null(value) || !length(value) || is.na(value[[1L]]) ||
        !nzchar(trimws(as.character(value[[1L]])))) {
      return("")
    }
    paste0(labels[[name]], ": ", trimws(as.character(value[[1L]])))
  }, character(1))
  paste(values[nzchar(values)], collapse = "; ")
}

stepwise_status_label <- function(selected, carry_status) {
  if (identical(tolower(carry_status), "final")) return("Final step")
  if (!isTRUE(selected)) return("Comparison")
  "Carried forward"
}

stepwise_stage_table <- function(nodes, job_map) {
  table <- data.frame(
    step_id = nodes$step_id,
    model = nodes$model_label,
    change = stepwise_sentence(nodes$change_axis),
    decision = mapply(
      stepwise_status_label,
      as.logical(nodes$selected),
      as.character(nodes$carry_status),
      USE.NAMES = FALSE
    ),
    notes = stepwise_sentence(
      if ("report_purpose" %in% names(nodes)) {
        nodes$report_purpose
      } else {
        nodes$control_notes
      }
    ),
    stringsAsFactors = FALSE
  )
  table$settings <- vapply(seq_len(nrow(nodes)), function(i) {
    stepwise_settings(nodes[i, , drop = FALSE])
  }, character(1))
  parent_index <- match(nodes$scientific_parent_id, nodes$step_id)
  repeated <- !is.na(parent_index) &
    table$settings == table$settings[parent_index]
  table$settings[repeated] <- ""
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
      "<col style=\"width:23%\"><col style=\"width:25%\">",
      "<col style=\"width:34%\"><col style=\"width:12%\"><col style=\"width:6%\">"
    )
  } else {
    paste0(
      "<col style=\"width:24%\"><col style=\"width:27%\">",
      "<col style=\"width:36%\"><col style=\"width:13%\">"
    )
  }
  rows <- vapply(seq_len(nrow(table)), function(i) {
    purpose <- trimws(table$notes[[i]])
    settings <- trimws(table$settings[[i]])
    detail <- paste0(
      if (nzchar(purpose)) paste0(
        "<div class=\"setting-line\"><span class=\"setting-label\">Purpose</span>",
        stepwise_html_escape(purpose), "</div>"
      ) else "",
      if (nzchar(settings)) paste0(
        "<div class=\"row-note\"><span class=\"setting-label\">Key setting</span>",
        stepwise_html_escape(settings), "</div>"
      ) else ""
    )
    job_cell <- if (include_jobs) {
      value <- table$job_number[[i]]
      paste0("<td class=\"job\">", if (is.na(value)) "" else paste0("#", value), "</td>")
    } else ""
    paste0(
      "<tr><td><div class=\"stage-title\">", stepwise_html_escape(table$model[[i]]),
      "</div><span class=\"stage-id\">", stepwise_html_escape(table$step_id[[i]]), "</span></td>",
      "<td>", stepwise_html_escape(table$change[[i]]), "</td>",
      "<td>", detail, "</td><td><span class=\"decision ",
      tolower(gsub(" ", "-", table$decision[[i]], fixed = TRUE)), "\">",
      stepwise_html_escape(table$decision[[i]]), "</span></td>", job_cell, "</tr>"
    )
  }, character(1))
  paste0(
    "<table id=\"stage-table\"><colgroup>", colgroup, "</colgroup>",
    "<thead><tr><th>Stage</th><th>Change evaluated</th>",
    "<th>Purpose and implementation</th><th>Decision</th>", job_header,
    "</tr></thead><tbody>", paste(rows, collapse = ""), "</tbody></table>"
  )
}

stepwise_table_latex <- function(table, include_jobs = FALSE) {
  columns <- if (include_jobs) {
    "@{}p{0.21\\linewidth}p{0.23\\linewidth}p{0.32\\linewidth}p{0.12\\linewidth}r@{}"
  } else {
    "@{}p{0.22\\linewidth}p{0.25\\linewidth}p{0.36\\linewidth}p{0.13\\linewidth}@{}"
  }
  header <- if (include_jobs) {
    "Stage & Change evaluated & Purpose and implementation & Decision & Job"
  } else {
    "Stage & Change evaluated & Purpose and implementation & Decision"
  }
  rows <- vapply(seq_len(nrow(table)), function(i) {
    detail <- paste(
      c(table$notes[[i]], table$settings[[i]])[
        nzchar(c(table$notes[[i]], table$settings[[i]]))
      ],
      collapse = " "
    )
    stage <- paste0(
      "\\textbf{", stepwise_latex_escape(table$model[[i]]), "}\\\\[-1pt]",
      "{\\scriptsize\\texttt{", stepwise_latex_escape(table$step_id[[i]]), "}}"
    )
    values <- c(
      stage,
      stepwise_latex_escape(table$change[[i]]),
      stepwise_latex_escape(detail),
      stepwise_latex_escape(table$decision[[i]])
    )
    if (include_jobs) {
      values <- c(values, if (is.na(table$job_number[[i]])) "" else paste0("\\#", table$job_number[[i]]))
    }
    paste0(paste(values, collapse = " & "), " \\\\")
  }, character(1))
  paste0(
    "% Requires \\usepackage{booktabs,longtable,array}\n",
    "\\begingroup\n\\small\n\\setlength{\\tabcolsep}{4pt}\n\\renewcommand{\\arraystretch}{1.15}\n",
    "\\begin{longtable}{", columns, "}\n",
    "\\caption{Stepwise model configurations evaluated during development of the BET 2026 assessment.}",
    "\\label{tab:bet-stepwise-development}\\\\\n",
    "\\toprule\n", header, " \\\\\n\\midrule\n\\endfirsthead\n",
    "\\toprule\n", header, " \\\\\n\\midrule\n\\endhead\n",
    paste(rows, collapse = "\n"), "\n\\bottomrule\n\\end{longtable}\n\\endgroup\n"
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
  discovered <- stepwise_discover_results(job_map, input_dir)
  result_bundle <- stepwise_render_result_bundle(discovered, output_dir)

  selected_count <- sum(nodes$selected, na.rm = TRUE)
  comparison_count <- nrow(nodes) - selected_count
  endpoint <- nodes$model_label[tolower(nodes$carry_status) == "final"]
  endpoint <- if (length(endpoint)) endpoint[[1L]] else nodes$model_label[[nrow(nodes)]]
  method_text <- paste0(
    "Model development proceeded stepwise. Each configuration changed one defined component ",
    "relative to its scientific parent, allowing the effect of that change to be evaluated ",
    "while the remaining settings were retained. Configurations supported for continued ",
    "development formed the main pathway; alternative branches recorded comparisons that ",
    "were examined but not carried forward. The table documents what changed at every step, ",
    "why the change was evaluated and the key implementation settings. The final step in this ",
    "pathway is ", endpoint, "."
  )
  figure_caption <- paste0(
    "Stepwise model-development pathway for the BET 2026 assessment. Solid teal arrows ",
    "show configurations carried forward; dashed grey arrows show comparison branches. ",
    "The coral node marks the final step in this pathway."
  )
  table_caption <- paste0(
    "Model-development steps evaluated for the BET 2026 assessment. Each row identifies the ",
    "change introduced relative to its scientific parent, its purpose and implementation, ",
    "and whether it was carried forward."
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
      "<section><h2>Fitted-model results</h2>",
      "<p>Results are included only for explicitly mapped completed jobs.</p>",
      "<table class=\"compact\"><thead><tr><th>Step</th><th>Job</th><th>Status</th></tr></thead><tbody>",
      result_rows, "</tbody></table>", iframe, "</section>"
    )
  }

  latex_figure <- paste0(
    "\\begin{figure}[htbp]\n\\centering\n",
    "\\includegraphics[width=\\linewidth]{pathway/figures/bet-2026-stepwise-pathway.png}\n",
    "\\caption{", stepwise_latex_escape(figure_caption), "}\n",
    "\\label{fig:bet-stepwise-pathway}\n\\end{figure}\n"
  )

  html_file <- file.path(output_dir, "bet-2026-stepwise-model-development.html")
  html <- paste0(
    "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">",
    "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">",
    "<title>BET 2026 model development</title><style>",
    ":root{--ink:#173042;--muted:#587080;--teal:#0d666d;--paper:#fbfaf7;--line:#d7e0e3;--coral:#c5422b}",
    "*{box-sizing:border-box}body{margin:0;background:#e9f0f0;color:var(--ink);font-family:Cambria,Georgia,serif;",
    "font-size:17px;line-height:1.52}.page{max-width:1540px;margin:28px auto;background:var(--paper);padding:48px 52px;",
    "box-shadow:0 18px 55px rgba(23,48,66,.13)}h1{font-size:2.25rem;margin:0 0 8px}h2{margin:42px 0 12px;",
    "font-size:1.55rem;border-bottom:2px solid var(--teal);padding-bottom:7px}p{max-width:1000px}.lede{font-size:1.08rem;",
    "color:var(--muted);margin-top:0}.summary{display:flex;gap:12px;flex-wrap:wrap;margin:22px 0}.pill{border:1px solid #bdd0d4;",
    "background:#eff6f5;border-radius:999px;padding:7px 14px;font-weight:700}.figure-shell{overflow-x:auto;border:1px solid var(--line);",
    "background:#fff;padding:10px}.dag-figure{display:block;width:100%;height:auto;min-width:1080px}figcaption,.caption{margin-top:12px;",
    "font-size:1rem;color:#294451}.actions{display:flex;gap:9px;flex-wrap:wrap;margin:13px 0 5px}button,a.button{border:0;",
    "background:var(--teal);color:#fff;padding:10px 14px;border-radius:6px;font:700 .93rem Georgia,serif;cursor:pointer;text-decoration:none}",
    "button.secondary{background:#fff;color:var(--teal);border:1px solid var(--teal)}.table-shell{width:100%;overflow-x:auto;margin:14px 0 18px}",
    "table{width:100%;border-collapse:collapse;font-size:.92rem;table-layout:fixed}th{background:#e8f1f1;text-align:left;border-top:2px solid var(--ink);",
    "border-bottom:1px solid var(--ink);padding:11px 13px;line-height:1.25}td{vertical-align:top;padding:12px 13px;border-bottom:1px solid var(--line);",
    "overflow-wrap:anywhere;word-break:normal;hyphens:auto}.stage-title{font-weight:700;line-height:1.28}.stage-id{display:block;margin-top:4px;",
    "font:600 .76rem/1.25 ui-monospace,SFMono-Regular,Consolas,monospace;color:var(--muted);letter-spacing:.01em}.setting-line{line-height:1.38}",
    ".setting-label{display:block;font:700 .72rem/1.2 ui-sans-serif,sans-serif;text-transform:uppercase;letter-spacing:.055em;color:var(--teal);",
    "margin-bottom:3px}.row-note{font-size:.86rem;line-height:1.38;color:var(--muted);margin-top:7px}.job{font-weight:700;white-space:nowrap}",
    ".decision{display:inline-block;",
    "padding:3px 8px;border-radius:999px;background:#e5f1ef;color:#07545a;font-weight:700;white-space:nowrap}.decision.comparison{background:#fff4dc;",
    "color:#8a5b00}.decision.final-step{background:#fbe7e2;color:#9c2d1c}.note{padding:13px 16px;border-left:4px solid var(--teal);",
    "background:#eff5f5;color:#3a5967}.hidden-copy{position:absolute;left:-100000px;white-space:pre-wrap}.results-frame{width:100%;height:1100px;",
    "border:1px solid var(--line);background:#fff}.compact{max-width:700px}@media(max-width:760px){.page{margin:0;padding:28px 18px}",
    "body{font-size:16px}table{font-size:.84rem;min-width:900px}.dag-figure{min-width:980px}}@media print{body{background:#fff}.page{box-shadow:none;",
    "margin:0;max-width:none;padding:0}button,.actions{display:none}h2{break-after:avoid}figure{break-inside:avoid}thead{display:table-header-group}",
    "tr{break-inside:avoid}.table-shell{overflow:visible}}",
    "</style></head><body><main class=\"page\"><header><h1>BET 2026 model development</h1>",
    "<p class=\"lede\">Stepwise assessment pathway and configuration record</p></header>",
    "<section><h2>Model-development approach</h2><p id=\"method-text\">", stepwise_html_escape(method_text), "</p>",
    "<div class=\"actions\"><button onclick=\"copyHtml('method-text',this)\">Copy analysis for Word</button>",
    "<button class=\"secondary\" onclick=\"copyText('method-latex',this)\">Copy analysis for LaTeX</button></div></section>",
    "<section><h2>Model pathway</h2><figure><div class=\"figure-shell\"><img class=\"dag-figure\" alt=\"BET 2026 stepwise model-development pathway\" src=\"data:image/png;base64,", png_data, "\">",
    "</div><figcaption id=\"figure-caption\"><strong>Figure <span contenteditable=\"true\">XX</span>.</strong> ",
    stepwise_html_escape(figure_caption), "</figcaption></figure>",
    "<div class=\"actions\"><button onclick=\"copyFigure(this)\">Copy figure for Word</button>",
    "<a class=\"button\" download href=\"data:image/png;base64,", png_data, "\">Save PNG</a>",
    "<button class=\"secondary\" onclick=\"copyText('figure-latex',this)\">Copy LaTeX figure</button></div></section>",
    "<section><h2>Model-development steps</h2><p class=\"caption\" id=\"table-caption\"><strong>Table ",
    "<span contenteditable=\"true\">XX</span>.</strong> ", stepwise_html_escape(table_caption), "</p>",
    "<div class=\"table-shell\">", table_html, "</div><div class=\"actions\"><button onclick=\"copyTable(this)\">Copy table for Word</button>",
    "<button class=\"secondary\" onclick=\"copyText('table-latex',this)\">Copy table for LaTeX</button></div></section>",
    result_section,
    "<pre id=\"method-latex\" class=\"hidden-copy\">", stepwise_html_escape(method_text), "</pre>",
    "<pre id=\"figure-latex\" class=\"hidden-copy\">", stepwise_html_escape(latex_figure), "</pre>",
    "<pre id=\"table-latex\" class=\"hidden-copy\">", stepwise_html_escape(table_latex), "</pre>",
    "<img id=\"dag-png\" hidden src=\"data:image/png;base64,", png_data, "\">",
    "<script>",
    "function feedback(b,t){const x=b.textContent;b.textContent=t;setTimeout(()=>b.textContent=x,1400)}",
    "async function copyText(id,b){try{await navigator.clipboard.writeText(document.getElementById(id).textContent);feedback(b,'Copied')}",
    "catch(e){feedback(b,'Copy failed')}}",
    "async function writeClipboard(html,text,b){try{await navigator.clipboard.write([new ClipboardItem({'text/html':new Blob([html],{type:'text/html'}),",
    "'text/plain':new Blob([text],{type:'text/plain'})})]);feedback(b,'Copied')}catch(e){try{await navigator.clipboard.writeText(text);",
    "feedback(b,'Copied as text')}catch(x){feedback(b,'Copy failed')}}}",
    "function copyHtml(id,b){const e=document.getElementById(id);writeClipboard(e.outerHTML,e.innerText,b)}",
    "function copyTable(b){const c=document.getElementById('table-caption'),t=document.getElementById('stage-table'),x=t.cloneNode(true);",
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
  write.csv(table, file.path(output_dir, "stepwise-model-configurations.csv"), row.names = FALSE)
  writeLines(table_latex, file.path(output_dir, "stepwise-model-configurations.tex"))
  writeLines(paste0("Figure XX. ", figure_caption), file.path(output_dir, "stepwise-pathway-caption.txt"))
  writeLines(paste0("Table XX. ", table_caption), file.path(output_dir, "stepwise-table-caption.txt"))

  invisible(list(
    html = html_file,
    pathway = dag,
    configurations = file.path(output_dir, "stepwise-model-configurations.csv"),
    discovered_results = discovered
  ))
}

`%||%` <- function(x, y) if (is.null(x) || !length(x) || is.na(x[[1L]])) y else x

if (sys.nframe() == 0L) {
  build_stepwise_report()
}
