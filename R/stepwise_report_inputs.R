# Runtime discovery and report-asset helpers for the stepwise report task.

stepwise_empty_source_index <- function() {
  data.frame(
    order = integer(), row = character(), step_id = character(),
    job_number = integer(), job_title = character(), model_label = character(),
    change_axis = character(), scientific_parent_id = character(),
    selected = logical(), task = character(), status = character(),
    stringsAsFactors = FALSE
  )
}

stepwise_json_records <- function(value) {
  value <- trimws(as.character(value %||% ""))
  if (!nzchar(value)) return(stepwise_empty_source_index())
  parsed <- jsonlite::fromJSON(value, simplifyDataFrame = TRUE)
  if (is.list(parsed) && !is.data.frame(parsed) && "models" %in% names(parsed)) {
    parsed <- parsed$models
  }
  if (!is.data.frame(parsed)) parsed <- as.data.frame(parsed, stringsAsFactors = FALSE)
  defaults <- stepwise_empty_source_index()
  for (name in names(defaults)) {
    if (!name %in% names(parsed)) parsed[[name]] <- defaults[[name]][NA_integer_]
  }
  parsed <- parsed[, names(defaults), drop = FALSE]
  parsed$order <- suppressWarnings(as.integer(parsed$order))
  missing_order <- is.na(parsed$order)
  parsed$order[missing_order] <- seq_len(nrow(parsed))[missing_order]
  parsed$job_number <- suppressWarnings(as.integer(parsed$job_number))
  parsed$selected <- as.logical(parsed$selected)
  parsed$selected[is.na(parsed$selected)] <- TRUE
  parsed[order(parsed$order), , drop = FALSE]
}

stepwise_repository_source_index <- function(input_dir) {
  candidates <- file.path(input_dir, c("source-index.csv", "model-index.csv"))
  candidates <- candidates[file.exists(candidates)]
  if (!length(candidates)) return(stepwise_empty_source_index())
  parsed <- utils::read.csv(candidates[[1L]], stringsAsFactors = FALSE, check.names = FALSE)
  defaults <- stepwise_empty_source_index()
  for (name in names(defaults)) {
    if (!name %in% names(parsed)) parsed[[name]] <- NA
  }
  parsed <- parsed[, names(defaults), drop = FALSE]
  parsed$order <- suppressWarnings(as.integer(parsed$order))
  missing_order <- is.na(parsed$order)
  parsed$order[missing_order] <- seq_len(nrow(parsed))[missing_order]
  parsed$job_number <- suppressWarnings(as.integer(parsed$job_number))
  parsed$selected <- as.logical(parsed$selected)
  parsed$selected[is.na(parsed$selected)] <- TRUE
  parsed[order(parsed$order), , drop = FALSE]
}

stepwise_provenance_records <- function(input_dir) {
  file <- file.path(input_dir, "kflow-provenance.json")
  if (!file.exists(file)) return(data.frame())
  provenance <- tryCatch(
    jsonlite::fromJSON(file, simplifyVector = FALSE),
    error = function(e) list()
  )
  inputs <- provenance$inputs %||% list()
  if (!length(inputs)) return(data.frame())
  rows <- lapply(inputs, function(item) {
    data.frame(
      job_number = suppressWarnings(as.integer(item$job_number %||% NA_integer_)),
      job_id = as.character(item$job_id %||% item$id %||% ""),
      job_title = as.character(item$job_title %||% ""),
      job_key = as.character(item$job_key %||% ""),
      task = as.character(item$task %||% ""),
      status = as.character(item$status %||% ""),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

stepwise_find_job_root <- function(input_dir, job_id) {
  direct <- file.path(input_dir, job_id)
  if (nzchar(job_id) && dir.exists(direct)) return(direct)
  children <- list.dirs(input_dir, recursive = FALSE, full.names = TRUE)
  match <- children[basename(children) == job_id]
  if (length(match)) match[[1L]] else ""
}

stepwise_discover_payload_index <- function(input_dir, source_index) {
  provenance <- stepwise_provenance_records(input_dir)
  if (!nrow(provenance)) {
    if (!nrow(source_index)) source_index <- stepwise_repository_source_index(input_dir)
    if (!nrow(source_index)) return(data.frame())
    records <- lapply(seq_len(nrow(source_index)), function(i) {
      step_id <- as.character(source_index$step_id[[i]])
      payload <- file.path(input_dir, "models", step_id, "model_payload.rds")
      if (!file.exists(payload)) return(NULL)
      data.frame(
        step_id = step_id,
        job_number = source_index$job_number[[i]],
        job_title = source_index$job_title[[i]],
        model_label = source_index$model_label[[i]],
        payload = normalizePath(payload, winslash = "/", mustWork = TRUE),
        status = source_index$status[[i]],
        stringsAsFactors = FALSE
      )
    })
    records <- Filter(Negate(is.null), records)
    if (!length(records)) return(data.frame())
    result <- do.call(rbind, records)
    rownames(result) <- NULL
    return(result)
  }
  records <- lapply(seq_len(nrow(provenance)), function(i) {
    root <- stepwise_find_job_root(input_dir, provenance$job_id[[i]])
    if (!nzchar(root)) return(NULL)
    payloads <- list.files(
      root, pattern = "^model_payload[.]rds$", recursive = TRUE, full.names = TRUE
    )
    payloads <- payloads[!grepl("/(jitter|retro|hessian|profile|selftest)/", payloads)]
    preferred <- payloads[grepl("/outputs/models/[^/]+/model_payload[.]rds$", payloads)]
    payload <- if (length(preferred)) preferred[[1L]] else if (length(payloads)) payloads[[1L]] else ""
    if (!nzchar(payload)) return(NULL)
    step_id <- basename(dirname(payload))
    mapped <- match(provenance$job_number[[i]], source_index$job_number)
    data.frame(
      step_id = if (!is.na(mapped) && nzchar(source_index$step_id[[mapped]])) source_index$step_id[[mapped]] else step_id,
      job_number = provenance$job_number[[i]],
      job_title = if (!is.na(mapped)) source_index$job_title[[mapped]] else provenance$job_title[[i]],
      model_label = if (!is.na(mapped)) source_index$model_label[[mapped]] else step_id,
      payload = payload,
      status = provenance$status[[i]],
      stringsAsFactors = FALSE
    )
  })
  records <- Filter(Negate(is.null), records)
  if (!length(records)) return(data.frame())
  result <- do.call(rbind, records)
  order_index <- match(result$job_number, source_index$job_number)
  result <- result[order(ifelse(is.na(order_index), Inf, order_index), result$step_id), , drop = FALSE]
  rownames(result) <- NULL
  result
}

stepwise_find_upstream_bundle <- function(input_dir, viewer_job = "") {
  viewers <- list.files(
    input_dir, pattern = "^interactive-model-viewer[.]html$",
    recursive = TRUE, full.names = TRUE
  )
  viewers <- viewers[grepl("/outputs/overview/interactive-model-viewer[.]html$", viewers)]
  if (!length(viewers)) return(list(root = "", viewer = ""))
  candidates <- lapply(viewers, function(viewer) {
    root <- dirname(dirname(viewer))
    score <- as.integer(file.exists(file.path(root, "indices", "figure-index.csv"))) * 4L +
      as.integer(file.exists(file.path(root, "analysis-manifest.json"))) * 2L +
      as.integer(file.exists(file.path(root, "indices", "table-index.csv")))
    if (nzchar(viewer_job) && grepl(paste0("(^|/)", viewer_job, "(/|$)"), viewer)) score <- score + 10L
    list(root = root, viewer = viewer, score = score)
  })
  best <- candidates[[which.max(vapply(candidates, `[[`, integer(1), "score"))]]
  best[c("root", "viewer")]
}

stepwise_copy_directory <- function(from, to) {
  if (!dir.exists(from)) return(FALSE)
  dir.create(to, recursive = TRUE, showWarnings = FALSE)
  files <- list.files(from, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  if (!length(files)) return(TRUE)
  relative <- substring(files, nchar(normalizePath(from)) + 2L)
  directories <- files[dir.exists(files)]
  if (length(directories)) {
    dir.create(file.path(to, substring(directories, nchar(normalizePath(from)) + 2L)),
               recursive = TRUE, showWarnings = FALSE)
  }
  regular <- files[file.exists(files) & !dir.exists(files)]
  if (length(regular)) {
    targets <- file.path(to, substring(regular, nchar(normalizePath(from)) + 2L))
    invisible(mapply(function(source, target) {
      dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
      file.copy(source, target, overwrite = TRUE, copy.date = TRUE)
    }, regular, targets))
  }
  TRUE
}

stepwise_extract_viewer_data <- function(viewer) {
  if (!file.exists(viewer)) return(list())
  lines <- readLines(viewer, warn = FALSE, encoding = "UTF-8")
  marker <- grep('<script type="application/json" id="viewer-data">', lines, fixed = TRUE)
  if (!length(marker) || marker[[1L]] >= length(lines)) return(list())
  tryCatch(
    jsonlite::fromJSON(lines[[marker[[1L]] + 1L]], simplifyVector = FALSE),
    error = function(e) list()
  )
}

stepwise_payload_likelihood_components <- function(input_dir, source_index) {
  core <- c("Tag", "Length frequency", "Weight frequency", "Age", "CPUE", "Catch")
  rows <- lapply(source_index$step_id, function(step_id) {
    file <- file.path(input_dir, "models", step_id, "model_payload.rds")
    if (!file.exists(file)) return(NULL)
    payload <- readRDS(file)
    likelihood <- payload$data$LikelihoodComponents %||% list()
    if (!length(likelihood)) return(NULL)
    likelihood <- as.data.frame(likelihood, stringsAsFactors = FALSE)
    if (!all(c("Component", "Value") %in% names(likelihood))) return(NULL)
    value <- function(component) {
      matched <- likelihood$Value[match(component, likelihood$Component)]
      if (!length(matched) || !is.finite(matched)) 0 else as.numeric(matched)
    }
    penalty <- sum(likelihood$Value[
      !likelihood$Component %in% c(core, "Unclassified objective residual")
    ], na.rm = TRUE)
    data.frame(
      Model = step_id,
      `Total objective` = as.numeric(payload$obj_fun[[1L]]),
      Tag = value("Tag"),
      `Length frequency` = value("Length frequency"),
      `Weight frequency` = value("Weight frequency"),
      Age = value("Age"),
      CPUE = value("CPUE"),
      Catch = value("Catch"),
      Penalty = penalty,
      check.names = FALSE,
      stringsAsFactors = FALSE
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) return(data.frame())
  do.call(rbind, rows)
}

stepwise_simplify_viewer <- function(
  viewer,
  hessian_audit_file = "",
  likelihood_components = data.frame()
) {
  if (!file.exists(viewer)) return(FALSE)
  lines <- readLines(viewer, warn = FALSE, encoding = "UTF-8")
  marker <- grep('<script type="application/json" id="viewer-data">', lines, fixed = TRUE)
  if (length(marker) != 1L || marker[[1L]] >= length(lines)) {
    stop("The interactive viewer JSON payload could not be located.", call. = FALSE)
  }
  data_line <- marker[[1L]] + 1L
  viewer_data <- jsonlite::fromJSON(lines[[data_line]], simplifyVector = FALSE)
  audit <- if (nzchar(hessian_audit_file) && file.exists(hessian_audit_file)) {
    utils::read.csv(hessian_audit_file, stringsAsFactors = FALSE, check.names = FALSE)
  } else data.frame()

  viewer_data$metrics <- lapply(viewer_data$metrics, function(metric) {
    key <- as.character(metric$key %||% "")
    if (identical(key, "model_summary")) {
      keep <- c(
        "Model", "Max gradient", "Objective value", "Active parameters",
        "Hessian PDH", "Non-positive eigenvalues", "Smallest eigenvalue"
      )
      keep <- keep[keep %in% names(metric$records)]
      metric$records <- metric$records[keep]
      metric$columns <- as.list(keep)
      metric$label <- "Fit diagnostics"
      models <- unlist(metric$records$Model, use.names = FALSE)
      pdh <- rep("Not evaluated", length(models))
      nonpositive <- as.list(rep("", length(models)))
      smallest <- as.list(rep("", length(models)))
      if (nrow(audit)) {
        matched <- match(models, audit$step_id)
        found <- !is.na(matched)
        pdh[found] <- as.character(audit$pdh[matched[found]])
        numeric_or_blank <- function(value) {
          parsed <- suppressWarnings(as.numeric(value))
          as.list(ifelse(is.finite(parsed), parsed, ""))
        }
        nonpositive[found] <- numeric_or_blank(audit$nonpositive_eigenvalues[matched[found]])
        smallest[found] <- numeric_or_blank(audit$smallest_eigenvalue[matched[found]])
      }
      metric$records[["Hessian PDH"]] <- as.list(pdh)
      metric$records[["Non-positive eigenvalues"]] <- nonpositive
      metric$records[["Smallest eigenvalue"]] <- smallest
    } else if (identical(key, "objective_components")) {
      metric$label <- "Likelihood components"
      if (nrow(likelihood_components)) {
        metric$records <- lapply(likelihood_components, as.list)
        metric$columns <- as.list(names(likelihood_components))
      }
    }
    metric
  })
  lines[[data_line]] <- as.character(jsonlite::toJSON(
    viewer_data, auto_unbox = TRUE, null = "null", na = "null", digits = NA
  ))
  # The stepwise report uses only the adopted 20% depletion LRP.
  lines <- gsub(
    "[{v:0.2,c:'#b73e3e'},{v:0.5,c:'#3f8f53'}]",
    "[{v:0.2,c:'#b73e3e'}]", lines, fixed = TRUE
  )
  # Keep the public offline viewer portable. Older mfclshiny bundles could
  # retain the machine-specific prefix of a payload path in embedded JSON.
  lines <- gsub(
    paste0(
      "(?i)(?:[A-Za-z]:)?[/\\\\][^\"'<>[:space:]]*",
      "[/\\\\]data[/\\\\]stepwise[/\\\\]models[/\\\\]",
      "([^/\\\\\"'<>[:space:]]+)[/\\\\]model_payload[.]rds"
    ),
    "data/stepwise/models/\\1/model_payload.rds",
    lines,
    perl = TRUE
  )
  private_patterns <- c(
    "/home/", "/var/lib/condor", "KflowOutput", "suvofp", "corp.spc",
    "AKIA", "ghp_"
  )
  leaked <- private_patterns[vapply(
    private_patterns, function(pattern) any(grepl(pattern, lines, fixed = TRUE)),
    logical(1)
  )]
  if (length(leaked)) {
    stop(
      "The public interactive viewer contains private or machine-specific metadata: ",
      paste(leaked, collapse = ", "),
      call. = FALSE
    )
  }
  writeLines(lines, viewer, useBytes = TRUE)
  TRUE
}

stepwise_metric_table <- function(viewer_data, key) {
  metrics <- viewer_data$metrics %||% list()
  selected <- Filter(function(metric) identical(as.character(metric$key %||% ""), key), metrics)
  if (!length(selected)) return(data.frame())
  records <- selected[[1L]]$records %||% list()
  if (!length(records)) return(data.frame())
  columns <- lapply(records, function(values) unlist(values, use.names = FALSE))
  as.data.frame(columns, stringsAsFactors = FALSE, check.names = FALSE)
}

stepwise_source_index_from_viewer <- function(viewer_data) {
  models <- viewer_data$models %||% list()
  keys <- unlist(models$key %||% character(), use.names = FALSE)
  labels <- unlist(models$label %||% keys, use.names = FALSE)
  if (!length(keys)) return(stepwise_empty_source_index())
  data.frame(
    order = seq_along(keys), row = sub("-.*$", "", keys), step_id = keys,
    job_number = NA_integer_, job_title = labels, model_label = labels,
    change_axis = labels, scientific_parent_id = c("", head(keys, -1L)),
    selected = TRUE, task = "", status = "completed",
    stringsAsFactors = FALSE
  )
}

stepwise_prepare_result_assets <- function(input_dir, output_dir, source_index) {
  viewer_job <- Sys.getenv("STEPWISE_VIEWER_JOB", "")
  upstream <- stepwise_find_upstream_bundle(input_dir, viewer_job)
  result_dir <- file.path(output_dir, "results")
  dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)

  if (nzchar(upstream$root)) {
    for (folder in c("figures", "indices", "tables")) {
      stepwise_copy_directory(file.path(upstream$root, folder), file.path(result_dir, folder))
    }
    for (file in c(
      "analysis-manifest.csv", "analysis-manifest.json", "report-files.csv",
      "mfclshiny-report-depletion-data.csv"
    )) {
      source <- file.path(upstream$root, file)
      if (file.exists(source)) file.copy(source, file.path(result_dir, file), overwrite = TRUE)
    }
  } else {
    payload_index <- stepwise_discover_payload_index(input_dir, source_index)
    if (nrow(payload_index)) {
      mfclshiny::build_report_figures(
        folders = unique(dirname(payload_index$payload)),
        output_dir = result_dir,
        title = paste(Sys.getenv("FLOW_SPECIES", "BET"), Sys.getenv("FLOW_ASSESSMENT_YEAR", "2026"), "stepwise model results"),
        figure_basename = "stepwise-model-results",
        formats = "png", build_payloads = FALSE, report_tables = TRUE,
        render_html = TRUE, html_file = "stepwise-model-results.html",
        optimize_figures = TRUE, interactive_viewer = TRUE,
        interactive_viewer_file = "interactive-model-viewer.html",
        species_code = Sys.getenv("FLOW_SPECIES", "BET"),
        species_label = Sys.getenv("FLOW_SPECIES_LABEL", "bigeye tuna"),
        assessment_year = Sys.getenv("FLOW_ASSESSMENT_YEAR", "2026")
      )
    }
  }

  viewer_candidates <- c(
    upstream$viewer,
    file.path(result_dir, "overview", "interactive-model-viewer.html"),
    file.path(result_dir, "interactive-model-viewer.html")
  )
  viewer_candidates <- viewer_candidates[file.exists(viewer_candidates)]
  viewer <- if (length(viewer_candidates)) viewer_candidates[[1L]] else ""
  public_viewer <- file.path(output_dir, "interactive-model-viewer.html")
  if (nzchar(viewer)) {
    file.copy(viewer, public_viewer, overwrite = TRUE, copy.date = TRUE)
    likelihood_components <- stepwise_payload_likelihood_components(input_dir, source_index)
    stepwise_simplify_viewer(
      public_viewer,
      file.path(normalizePath(input_dir, mustWork = TRUE), "hessian-audit.csv"),
      likelihood_components
    )
  }

  figure_index <- file.path(result_dir, "indices", "figure-index.csv")
  table_index <- file.path(result_dir, "indices", "table-index.csv")
  viewer_data <- stepwise_extract_viewer_data(if (file.exists(public_viewer)) public_viewer else viewer)
  model_summary <- stepwise_metric_table(viewer_data, "model_summary")
  objective_components <- stepwise_metric_table(viewer_data, "objective_components")
  if (nrow(model_summary)) write.csv(model_summary, file.path(output_dir, "stepwise-model-summary.csv"), row.names = FALSE)
  if (nrow(objective_components)) write.csv(objective_components, file.path(output_dir, "stepwise-objective-components.csv"), row.names = FALSE)

  list(
    result_dir = result_dir,
    viewer = if (file.exists(public_viewer)) public_viewer else "",
    viewer_data = viewer_data,
    figure_index = if (file.exists(figure_index)) read.csv(figure_index, check.names = FALSE) else data.frame(),
    table_index = if (file.exists(table_index)) read.csv(table_index, check.names = FALSE) else data.frame(),
    model_summary = model_summary,
    objective_components = objective_components,
    upstream_root = upstream$root
  )
}

stepwise_dynamic_table_html <- function(table, id, max_rows = Inf) {
  if (!is.data.frame(table) || !nrow(table)) return("<p class=\"note\">No rows were available.</p>")
  shown <- head(table, max_rows)
  header <- paste0("<th>", stepwise_html_escape(names(shown)), "</th>", collapse = "")
  rows <- vapply(seq_len(nrow(shown)), function(i) {
    cells <- vapply(shown[i, , drop = FALSE], function(value) {
      text <- if (!length(value) || is.na(value[[1L]])) "" else format(value[[1L]], digits = 7, trim = TRUE)
      paste0("<td>", stepwise_html_escape(text), "</td>")
    }, character(1))
    paste0("<tr>", paste(cells, collapse = ""), "</tr>")
  }, character(1))
  paste0("<table id=\"", id, "\"><thead><tr>", header, "</tr></thead><tbody>",
         paste(rows, collapse = ""), "</tbody></table>")
}

stepwise_figure_sections_html <- function(index, output_dir, viewer_url) {
  if (!is.data.frame(index) || !nrow(index)) return("")
  index <- index[index$status == "ok" & nzchar(index$file), , drop = FALSE]
  if (!nrow(index)) return("")
  priority <- c(
    "spatial-structure-comparison", "maturity-comparison",
    "stepwise-key-quantity-trajectories", "stepwise-key-quantity-changes",
    "key-quantities", "spawning-potential-with-without-fishing", "depletion-by-area",
    "recruitment-by-area", "f-juvenile-adult-by-area", "f-area-contribution",
    "kobe-plot", "majuro-plot", "region-map", "fishery-process", "cpue-fits",
    "cpue-residuals", "length-frequency", "length-frequency-residuals",
    "tagging-dynamics", "regional-movement", "population-biology", "growth-curve",
    "maturity-at-age", "natural-mortality-at-age"
  )
  rank <- match(index$figure, priority)
  index <- index[order(ifelse(is.na(rank), length(priority) + seq_len(nrow(index)), rank)), , drop = FALSE]
  cards <- vapply(seq_len(nrow(index)), function(i) {
    file <- file.path("results", "figures", index$file[[i]])
    source_file <- file.path(output_dir, file)
    image_src <- file
    if (file.exists(source_file)) {
      image_src <- paste0(
        "data:image/png;base64,",
        jsonlite::base64_enc(readBin(source_file, "raw", n = file.info(source_file)$size))
      )
    }
    pdf_file <- sub("[.]png$", ".pdf", file, ignore.case = TRUE)
    id <- paste0("result-figure-", i)
    figure_anchor <- paste0("fig-", gsub("[^a-z0-9]+", "-", tolower(index$figure[[i]])))
    latex_caption <- if ("latex_caption" %in% names(index) && nzchar(index$latex_caption[[i]])) {
      index$latex_caption[[i]]
    } else {
      stepwise_latex_escape(index$caption[[i]])
    }
    latex <- paste0(
      "% Requires \\usepackage{graphicx,hyperref}\n",
      "\\begin{figure}[htbp]\n\\centering\n",
      "\\includegraphics[width=\\linewidth,height=0.88\\textheight,keepaspectratio]{", pdf_file, "}\n",
      "\\caption{", latex_caption, "}\n",
      "\\label{fig:", gsub("[^a-z0-9]+", "-", tolower(index$figure[[i]])), "}\n",
      "\\par\\small\\href{", viewer_url, "}{Explore individual model configurations in the interactive viewer.}\n",
      "\\end{figure}\n"
    )
    paste0(
      "<figure class=\"result-figure\" id=\"", figure_anchor, "\">",
      "<a href=\"", stepwise_html_escape(viewer_url), "\" target=\"_blank\" rel=\"noopener\" title=\"Open the interactive viewer\"><img id=\"", id, "-image\" loading=\"lazy\" src=\"", image_src,
      "\" alt=\"", stepwise_html_escape(index$alt_text[[i]]), "\"></a>",
      "<figcaption id=\"", id, "-caption\"><strong>Figure.</strong> ",
      stepwise_html_escape(index$caption[[i]]), " <a href=\"", stepwise_html_escape(viewer_url), "\" target=\"_blank\" rel=\"noopener\">",
      "Explore individual configurations in the interactive viewer.</a></figcaption>",
      "<div class=\"actions\"><button onclick=\"copyResultFigure('", id, "-image','", id, "-caption',this)\">",
      "Copy figure + caption for Word</button>",
      "<a class=\"button\" href=\"", stepwise_html_escape(viewer_url), "\" target=\"_blank\" rel=\"noopener\">Open interactive viewer</a>",
      "<a class=\"button\" download href=\"", stepwise_html_escape(file), "\">Save PNG</a>",
      "<a class=\"button\" download href=\"", stepwise_html_escape(pdf_file), "\">Save vector PDF</a>",
      "<button class=\"secondary\" onclick=\"copyText('", id, "-latex',this)\">",
      "Copy figure + caption for LaTeX</button></div>",
      "<pre id=\"", id, "-latex\" class=\"hidden-copy\">", stepwise_html_escape(latex), "</pre></figure>"
    )
  }, character(1))
  paste0("<div class=\"result-grid\">", paste(cards, collapse = ""), "</div>")
}

stepwise_table_downloads_html <- function(index) {
  if (!is.data.frame(index) || !nrow(index)) return("")
  index <- index[index$status == "ok" & nzchar(index$file), , drop = FALSE]
  if (!nrow(index)) return("")
  items <- vapply(seq_len(nrow(index)), function(i) {
    paste0("<li><a href=\"results/tables/", stepwise_html_escape(index$file[[i]]), "\" download>",
           stepwise_html_escape(index$label[[i]]), "</a><span>",
           stepwise_html_escape(index$caption[[i]]), "</span></li>")
  }, character(1))
  paste0("<ul class=\"download-list\">", paste(items, collapse = ""), "</ul>")
}
