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
    "\\begin{longtable}{", columns, "}\n",
    "\\caption{Changes evaluated during stepwise development of the BET 2026 assessment and their rationale.}",
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

  method_text <- paste0(
    "Model development followed a stepwise pathway in which a defined model component or data ",
    "treatment was changed at each stage, while other inputs and controls were retained where ",
    "possible. Retained configurations formed the main pathway; sibling branches represented ",
    "alternatives. The final selected configuration used Dirichlet-multinomial (DM) composition ",
    "weighting."
  )
  figure_caption <- paste0(
    "Stepwise model-development pathway for the BET 2026 assessment. Solid teal arrows ",
    "show configurations carried forward; dashed orange arrows show comparison branches. ",
    "The dark-teal node marks the selected final model."
  )
  table_caption <- paste0(
    "Changes evaluated during stepwise development of the BET 2026 assessment and their ",
    "rationale. Step numbers correspond to the pathway in Figure XX."
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
    "background:#fff;padding:10px}.dag-figure{display:block;width:auto;height:auto;max-width:100%;max-height:calc(100vh - 190px);margin:0 auto}",
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
    ".note{padding:13px 16px;border-left:4px solid var(--sea);",
    "background:#eff5f5;color:#3a5967}.hidden-copy{position:absolute;left:-100000px;white-space:pre-wrap}.results-frame{width:100%;height:1100px;",
    "border:1px solid var(--line);background:#fff}.compact{max-width:700px}.action-status{position:fixed;right:22px;bottom:22px;z-index:20;",
    "background:var(--ink);color:#fff;padding:10px 15px;box-shadow:0 8px 24px rgba(18,59,93,.2);opacity:0;transform:translateY(8px);",
    "pointer-events:none;transition:opacity .16s ease,transform .16s ease}.action-status.show{opacity:1;transform:translateY(0)}",
    "@media(max-width:760px){main{padding:18px 10px 45px}table{font-size:.82rem;min-width:700px}}@media print{body{background:#fff}",
    "header{padding:0 0 20px;background:#fff;color:var(--ink)}header p{color:var(--muted)}main{max-width:none;padding:0}.overview,.model-card{border:0;padding:0;margin:0}",
    "button,.actions,.action-status{display:none}h2{break-after:avoid}figure{break-inside:avoid}thead{display:table-header-group}",
    "tr{break-inside:avoid}.table-shell{overflow:visible}}",
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
    result_section,
    "<pre id=\"method-latex\" class=\"hidden-copy\">", stepwise_html_escape(method_text), "</pre>",
    "<pre id=\"figure-latex\" class=\"hidden-copy\">", stepwise_html_escape(latex_figure), "</pre>",
    "<pre id=\"table-latex\" class=\"hidden-copy\">", stepwise_html_escape(table_latex), "</pre>",
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
  export_columns <- c("step", "change", "rationale")
  if (include_jobs) export_columns <- c(export_columns, "job_number")
  export_table <- table[export_columns]
  write.csv(
    export_table,
    file.path(output_dir, "stepwise-model-configurations.csv"),
    row.names = FALSE
  )
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
