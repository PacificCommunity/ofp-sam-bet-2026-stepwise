#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4L) {
  stop(
    "Usage: recover-jitter-fit.R BASE_PAR FITTED_MAPPING_RDS ",
    "JITTER_RESULT_RDS OUTPUT_PAR",
    call. = FALSE
  )
}

base_par <- normalizePath(args[[1L]], mustWork = TRUE)
mapping_file <- normalizePath(args[[2L]], mustWork = TRUE)
result_file <- normalizePath(args[[3L]], mustWork = TRUE)
output_par <- normalizePath(args[[4L]], mustWork = FALSE)

suppressPackageStartupMessages({
  library(FLR4MFCL)
  library(mfclkit)
})

mapping <- readRDS(mapping_file)
result <- readRDS(result_file)
labels <- result$fitted_parameter_changes$labels

required_mapping <- c(
  "Index", "target", "p1", "p2", "p3", "p4"
)
required_labels <- c(
  "Index", "target", "p1", "p2", "p3", "p4", "after"
)
if (!is.data.frame(mapping) || !nrow(mapping) ||
    !all(required_mapping %in% names(mapping))) {
  stop("The fitted semantic mapping is incomplete.", call. = FALSE)
}
if (!is.data.frame(labels) || !nrow(labels) ||
    !all(required_labels %in% names(labels))) {
  stop("The jitter fitted-parameter payload is incomplete.", call. = FALSE)
}

match_row <- match(mapping$Index, labels$Index)
if (anyNA(match_row) || anyDuplicated(labels$Index)) {
  stop("The fitted mapping and jitter payload indices do not match.", call. = FALSE)
}
labels <- labels[match_row, , drop = FALSE]

same_coordinate <- function(left, right) {
  (is.na(left) & is.na(right)) |
    (!is.na(left) & !is.na(right) & as.character(left) == as.character(right))
}
coordinate_fields <- c("target", "p1", "p2", "p3", "p4")
coordinate_ok <- vapply(
  coordinate_fields,
  function(field) all(same_coordinate(mapping[[field]], labels[[field]])),
  logical(1L)
)
if (!all(coordinate_ok)) {
  stop(
    "The fitted mapping and jitter payload semantic coordinates differ: ",
    paste(names(coordinate_ok)[!coordinate_ok], collapse = ", "),
    call. = FALSE
  )
}

proposal <- suppressWarnings(as.numeric(labels$after))
if (length(proposal) != nrow(mapping) || any(!is.finite(proposal))) {
  stop("The jitter payload does not contain a complete fitted vector.",
       call. = FALSE)
}

par_obj <- suppressWarnings(FLR4MFCL::read.MFCLPar(base_par))
s4_array <- getFromNamespace("mfk_indepvar_s4_array", "mfclkit")
set_s4_array <- getFromNamespace("mfk_indepvar_set_s4_array", "mfclkit")
dimensions <- getFromNamespace("mfk_indepvar_dimensions", "mfclkit")
flag <- getFromNamespace("mfk_indepvar_flag", "mfclkit")
fish_parameter_spec <- getFromNamespace(
  "mfk_indepvar_fish_parameter_spec", "mfclkit"
)
extract_mapping <- getFromNamespace(
  "mfk_jitter_final_values_from_mapping", "mfclkit"
)

for (target in unique(mapping$target)) {
  rows <- which(mapping$target == target)
  if (!length(rows) || is.na(target)) next

  if (target == "region_rec_var") {
    arr <- s4_array(par_obj, "region_rec_var")
    perm <- aperm(arr, c(4L, 2L, 5L, 1L, 3L, 6L))
    vec <- as.vector(perm)
    vec[mapping$p1[rows]] <- proposal[rows]
    perm[] <- vec
    arr <- aperm(perm, order(c(4L, 2L, 5L, 1L, 3L, 6L)))
    par_obj <- set_s4_array(par_obj, "region_rec_var", arr)
  } else if (target == "rel_rec_log") {
    arr <- s4_array(par_obj, "rel_rec")
    perm <- aperm(arr, c(4L, 2L, 1L, 3L, 5L, 6L))
    vec <- as.vector(perm)
    vec[mapping$p1[rows]] <- exp(proposal[rows])
    perm[] <- vec
    arr <- aperm(perm, order(c(4L, 2L, 1L, 3L, 5L, 6L)))
    par_obj <- set_s4_array(par_obj, "rel_rec", arr)
  } else if (target == "orth_coffs") {
    value <- methods::slot(par_obj, "orth_coffs")
    for (row in rows) {
      value[mapping$p1[[row]], mapping$p2[[row]]] <- proposal[[row]]
    }
    methods::slot(par_obj, "orth_coffs") <- value
  } else if (target == "fishery_sel_group") {
    arr <- s4_array(par_obj, "fishery_sel")
    dims <- dimensions(par_obj)
    groups <- flag(par_obj, -seq_len(dims[["fisheries"]]), 24L)
    active <- flag(par_obj, -seq_len(dims[["fisheries"]]), 48L)
    for (row in rows) {
      fisheries <- if (max(groups) > 0L) {
        which(groups == mapping$p4[[row]] & active > 0L)
      } else {
        mapping$p3[[row]]
      }
      arr[
        mapping$p1[[row]], 1L, fisheries, mapping$p2[[row]], 1L, 1L
      ] <- proposal[[row]]
    }
    par_obj <- set_s4_array(par_obj, "fishery_sel", arr)
  } else if (target == "fish_params_row") {
    value <- methods::slot(par_obj, "fish_params")
    dims <- dimensions(par_obj)
    n_fish <- dims[["fisheries"]]
    for (row in rows) {
      fish_row <- mapping$p1[[row]]
      representative <- mapping$p2[[row]]
      group_id <- mapping$p4[[row]]
      spec <- fish_parameter_spec(par_obj, fish_row)
      members <- representative
      if (!is.null(spec) && is.finite(group_id)) {
        group <- flag(par_obj, -seq_len(n_fish), as.integer(spec$group))
        active <- flag(par_obj, -seq_len(n_fish), as.integer(spec$active))
        if (max(group) > 0L) {
          members <- which(group == group_id & active != 0L)
        }
      }
      value[fish_row, members] <- proposal[[row]]
    }
    methods::slot(par_obj, "fish_params") <- value
  } else if (target == "growth_devs_age") {
    arr <- s4_array(par_obj, "growth_devs_age")
    perm <- aperm(arr, c(4L, 1L, 2L, 3L, 5L, 6L))
    vec <- as.vector(perm)
    vec[mapping$p1[rows]] <- proposal[rows]
    perm[] <- vec
    arr <- aperm(perm, order(c(4L, 1L, 2L, 3L, 5L, 6L)))
    par_obj <- set_s4_array(par_obj, "growth_devs_age", arr)
  } else if (target == "m_devs_age") {
    arr <- s4_array(par_obj, "m_devs_age")
    perm <- aperm(arr, c(4L, 1L, 2L, 3L, 5L, 6L))
    vec <- as.vector(perm)
    vec[mapping$p1[rows]] <- proposal[rows]
    perm[] <- vec
    arr <- aperm(perm, order(c(4L, 1L, 2L, 3L, 5L, 6L)))
    par_obj <- set_s4_array(par_obj, "m_devs_age", arr)
  } else if (target == "growth_curve_devs") {
    arr <- s4_array(par_obj, "growth_curve_devs")
    vec <- as.numeric(arr)
    vec[mapping$p1[rows]] <- proposal[rows]
    arr[] <- vec
    par_obj <- set_s4_array(par_obj, "growth_curve_devs", arr)
  } else if (target == "diff_coffs") {
    value <- methods::slot(par_obj, "diff_coffs")
    for (row in rows) {
      value[mapping$p1[[row]], mapping$p2[[row]]] <- proposal[[row]]
    }
    methods::slot(par_obj, "diff_coffs") <- value
  } else if (target == "tag_fish_rep_group") {
    group <- methods::slot(par_obj, "tag_fish_rep_grp")
    active <- methods::slot(par_obj, "tag_fish_rep_flags")
    value <- methods::slot(par_obj, "tag_fish_rep_rate")
    for (row in rows) {
      members <- which(group == mapping$p1[[row]] & active == 1L)
      value[members] <- proposal[[row]]
    }
    methods::slot(par_obj, "tag_fish_rep_rate") <- value
  } else if (target == "region_pars_row1") {
    value <- methods::slot(par_obj, "region_pars")
    dims <- dimensions(par_obj)
    n_region <- dims[["regions"]]
    group <- flag(par_obj, -100002L, seq_len(n_region))
    active <- flag(par_obj, -100000L, seq_len(n_region))
    for (row in rows) {
      group_id <- mapping$p4[[row]]
      members <- if (is.finite(group_id) && max(group) > 0L) {
        which(group == group_id & active != 0L)
      } else {
        mapping$p1[[row]]
      }
      value[1L, members] <- proposal[[row]]
    }
    methods::slot(par_obj, "region_pars") <- value
  } else if (target == "season_growth_pars") {
    value <- methods::slot(par_obj, "season_growth_pars")
    value[mapping$p1[rows]] <- proposal[rows]
    methods::slot(par_obj, "season_growth_pars") <- value
  } else if (target == "log_m_age_pars5") {
    arr <- s4_array(par_obj, "log_m")
    perm <- aperm(arr, c(4L, 1L, 2L, 3L, 5L, 6L))
    vec <- as.vector(perm)
    vec[mapping$p1[rows]] <- proposal[rows]
    perm[] <- vec
    arr <- aperm(perm, order(c(4L, 1L, 2L, 3L, 5L, 6L)))
    par_obj <- set_s4_array(par_obj, "log_m", arr)
  } else if (target == "growth_vb") {
    value <- methods::slot(par_obj, "growth")
    value[mapping$p1[rows], 1L] <- proposal[rows]
    methods::slot(par_obj, "growth") <- value
  } else if (target == "growth_richards") {
    methods::slot(par_obj, "richards") <- proposal[rows][[1L]]
  } else if (target == "growth_var") {
    value <- methods::slot(par_obj, "growth_var_pars")
    value[mapping$p1[rows], 1L] <- proposal[rows]
    methods::slot(par_obj, "growth_var_pars") <- value
  } else if (target == "tot_pop") {
    methods::slot(par_obj, "tot_pop") <- proposal[rows][[1L]]
  } else if (target == "rec_init_pop_diff") {
    methods::slot(par_obj, "rec_init_pop_diff") <- proposal[rows][[1L]]
  } else {
    stop("Unsupported fitted mapping target: ", target, call. = FALSE)
  }
}

if (is.finite(result$obj_fun)) {
  methods::slot(par_obj, "obj_fun") <- as.numeric(result$obj_fun)
}
if (is.finite(result$max_grad)) {
  methods::slot(par_obj, "max_grad") <- as.numeric(result$max_grad)
}

dir.create(dirname(output_par), recursive = TRUE, showWarnings = FALSE)
suppressWarnings(FLR4MFCL::write(par_obj, file = output_par))
reread <- suppressWarnings(FLR4MFCL::read.MFCLPar(output_par))
roundtrip <- extract_mapping(reread, mapping)
if (!isTRUE(roundtrip$ok) || length(roundtrip$values) != nrow(mapping)) {
  stop(
    "The recovered PAR failed semantic round-trip extraction: ",
    roundtrip$reason,
    call. = FALSE
  )
}

absolute_error <- abs(roundtrip$values - proposal)
tolerance <- 1e-7
if (any(!is.finite(absolute_error)) || max(absolute_error) > tolerance) {
  stop(
    "The recovered PAR failed semantic round-trip validation; max error = ",
    format(max(absolute_error), scientific = TRUE),
    call. = FALSE
  )
}

audit <- data.frame(
  Index = mapping$Index,
  Var_name = mapping$Var_name,
  target = mapping$target,
  expected = proposal,
  recovered = roundtrip$values,
  absolute_error = absolute_error,
  stringsAsFactors = FALSE
)
audit_file <- paste0(output_par, ".recovery-audit.csv")
utils::write.csv(audit, audit_file, row.names = FALSE)

cat(
  sprintf(
    paste0(
      "Recovered %d fitted active parameters; max round-trip error %.3e; ",
      "objective %.10f; max gradient %.3e\\n"
    ),
    nrow(mapping), max(absolute_error),
    as.numeric(methods::slot(reread, "obj_fun")),
    as.numeric(methods::slot(reread, "max_grad"))
  )
)
