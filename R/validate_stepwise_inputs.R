#!/usr/bin/env Rscript

## Fail-closed, read-only validation for the final BET 2026 stepwise chain.
## This script validates frozen inputs and controls; it never runs MFCL.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
failures <- character()
fail <- function(scope, message) {
  failures <<- c(failures, sprintf("[%s] %s", scope, message))
  invisible(FALSE)
}
assert <- function(value, scope, message) {
  if (!isTRUE(value)) fail(scope, message)
  invisible(value)
}

read_text <- function(path) readLines(path, warn = FALSE)
sha256_file <- function(path) {
  if (!file.exists(path)) return("")
  output <- system2("sha256sum", shQuote(path), stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  hash <- if (length(output)) strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]] else ""
  if ((!is.null(status) && status != 0L) || !grepl("^[0-9a-f]{64}$", hash)) {
    fail(path, "could not calculate SHA256")
    return("")
  }
  hash
}
sha256_text <- function(text) {
  path <- tempfile("stepwise-signature-")
  on.exit(unlink(path), add = TRUE)
  writeChar(text, path, eos = NULL, useBytes = TRUE)
  sha256_file(path)
}

config_env <- new.env(parent = baseenv())
tryCatch(
  sys.source(Sys.getenv("CONFIG_R", "job-config.R"), envir = config_env),
  error = function(e) fail("job-config", conditionMessage(e))
)
models <- get0("stepwise_models", envir = config_env, ifnotfound = data.frame())

expected_ids <- c(
  "01-Diag2023", "02-NewExeIni1007", "03-FixM", "04-LengthWeight",
  "05-NewStructure", "06-ConvertToLength", "07-AddLengthData",
  "08-DataTo2024", "09-SizeDataQC", "10-RegionalCPUE",
  "11-TimeVaryingCV", "12-CPUEErrorCalibration", "13-NewAgeData",
  "14a-REG075", "14b-SUB075", "15-SelectivityUpdate", "16-MIX020",
  "17-TagReportingExclusion", "18-EffortCreep", "19-DMG8Nmax25",
  "20-F10NDWeak"
)
expected_parents <- c(
  "external-2023-diagnostic-archive", expected_ids[1:13],
  "13-NewAgeData", "14b-SUB075", "15-SelectivityUpdate",
  "16-MIX020", "17-TagReportingExclusion", "18-EffortCreep",
  "19-DMG8Nmax25"
)
assert(is.data.frame(models), "job-config", "stepwise_models must be a data frame")
if (is.data.frame(models)) {
  assert(identical(as.character(models$step_id), expected_ids),
         "job-config", "step order or model set differs from the approved 21-row/20-step chain")
  assert(identical(as.character(models$scientific_parent_id), expected_parents),
         "job-config", "scientific parent graph differs from the approved cumulative chain")
  assert(sum(as.logical(models$selected)) == 20L,
         "job-config", "exactly 20 models must be on the selected path")
  assert(identical(models$step_id[!as.logical(models$selected)], "14a-REG075"),
         "job-config", "14a-REG075 must be the only alternative")
  assert(identical(as.character(models$mfcl_program_path[[1L]]),
                   "/home/mfcl/mfclo64_2023_diagnostic_2.2.2.0"),
         "job-config", "Step 01 must use the archived 2.2.2.0 diagnostic executable")
  assert(all(as.character(models$mfcl_program_path[-1L]) == "/home/mfcl/mfclo64"),
         "job-config", "Steps 02-19 must use tuna-flow v2.5 /home/mfcl/mfclo64")
}

actual_ids <- sort(basename(list.dirs(file.path(root, "steps"), recursive = FALSE)))
assert(identical(actual_ids, sort(expected_ids)), "folder-set",
       "steps/ must contain exactly the configured replacement folders")
forbidden_names <- c("TailCompression", "DOMDiv200", "Francis", "MIX015", "20c")
assert(!any(vapply(forbidden_names, function(x) any(grepl(x, actual_ids, fixed = TRUE)), logical(1))),
       "folder-set", "superseded tail-compression/DOM/Francis/MIX015/20c folders remain")

## Runtime lock.
kflow <- paste(read_text(file.path(root, "kflow.yaml")), collapse = "\n")
assert(grepl("name: bet-2026-final-stepwise-alt-f10-ndpen-weak-v25", kflow, fixed = TRUE),
       "kflow", "task name is not the deterministic F10 weak-penalty v2.5 task")
assert(grepl(
  "ghcr.io/pacificcommunity/tuna-flow:v2.5@sha256:c87f1f6d9d4f62dc447844b58afe35f96af175bf933cb6cffbbbe39a59172360",
  kflow, fixed = TRUE
), "kflow", "tuna-flow v2.5 digest changed")
for (value in c(
  "remote_host: suva",
  "PROGRAM_PATH: /home/mfcl/mfclo64",
  "MFCLKIT_GITHUB_REF: 04eff66ef90d38f24a1bb6b58ae750013d76ffeb",
  "MFCLSHINY_GITHUB_REF: 0185662038fca0740b0d91c0f8546431fce0bc07"
)) {
  assert(grepl(value, kflow, fixed = TRUE), "kflow", paste0("missing runtime lock: ", value))
}

## Public source lock.
lock_path <- Sys.getenv(
  "PUBLIC_RUN_PROVENANCE",
  file.path(root, "config", "public-run-provenance.csv")
)
lock <- tryCatch(
  utils::read.csv(lock_path, stringsAsFactors = FALSE, check.names = FALSE),
  error = function(e) {
    fail("provenance", conditionMessage(e))
    data.frame()
  }
)
required_lock_columns <- c(
  "role", "name", "repository_url", "repository_commit", "repository_path",
  "source_sha256", "prepared_sha256", "public_access", "status"
)
assert(all(required_lock_columns %in% names(lock)), "provenance",
       "public-run-provenance.csv schema is incomplete")
if (nrow(lock)) {
  locked <- lock[lock$status == "locked", , drop = FALSE]
  assert(nrow(locked) > 0L, "provenance", "no locked public source records")
  for (i in seq_len(nrow(locked))) {
    row <- locked[i, , drop = FALSE]
    scope <- paste0("provenance:", row$role, ":", row$name)
    assert(identical(tolower(row$public_access), "true"), scope,
           "locked source is not explicitly public")
    assert(grepl("^https://github[.]com/PacificCommunity/", row$repository_url), scope,
           "locked source is not a public PacificCommunity GitHub repository")
    assert(grepl("^[0-9a-f]{40}$", row$repository_commit), scope,
           "repository_commit is not a full SHA")
    assert(grepl("^[0-9a-f]{64}$", row$source_sha256), scope,
           "source_sha256 is invalid")
    assert(grepl("^[0-9a-f]{64}$", row$prepared_sha256), scope,
           "prepared_sha256 is invalid")
  }
  mix <- locked[locked$role == "ini_source" & locked$name == "MIX020", , drop = FALSE]
  assert(nrow(mix) == 1L, "provenance", "MIX020 source lock is missing or duplicated")
  if (nrow(mix) == 1L) {
    assert(identical(mix$repository_commit, "efe3107c72774ee73b5e6dc45e44cf51f0fc20e8"),
           "provenance", "MIX020 is not locked to SC22-IP10-regionMean commit efe3107")
    assert(identical(mix$repository_path, "BET/ini.mix-period/bet.2026.mix-0.2.ini"),
           "provenance", "MIX020 path is not the region-mean K=0.20 INI")
    assert(identical(mix$source_sha256,
                     "1e8c589854274248efcb8b08cc85b476e718d2f5d985e03873e973181ae11e94"),
           "provenance", "MIX020 source SHA changed")
  }
}

model_dir <- function(id) file.path(root, "steps", id, "model")
core_files <- c(
  "bet.frq", "bet.ini", "bet.tag", "bet.age_length", "doitall.sh",
  "mfcl.cfg", "fishery_map.R", "tag_rep_map.R",
  "bet.reg_scaling", "bet.reg_scaling.full"
)
required_base <- core_files[1:7]
qc_files <- c(
  "f15-lf-qc-audit.csv", "f15-lf-qc-summary.csv",
  "dom-lf-qc-audit.csv", "dom-lf-qc-summary.csv"
)

for (id in expected_ids) {
  dir <- model_dir(id)
  assert(dir.exists(dir), id, "model directory is missing")
  if (!dir.exists(dir)) next
  missing <- required_base[!file.exists(file.path(dir, required_base))]
  assert(!length(missing), id, paste0("missing required files: ", paste(missing, collapse = ", ")))
  assert(file.access(file.path(dir, "doitall.sh"), 1L) == 0L, id,
         "doitall.sh is not executable")
  if (!identical(id, "01-Diag2023")) {
    assert(file.exists(file.path(dir, "tag_rep_map.R")), id,
           "tag_rep_map.R is required after the diagnostic reference")
  }
  outputs <- list.files(dir, pattern = "(^|[.])(par|rep|fit)$", ignore.case = TRUE)
  assert(!length(outputs), id, "fitted MFCL outputs were committed with the inputs")
  manifest_path <- file.path(dirname(dir), "input_manifest.csv")
  assert(file.exists(manifest_path), id, "input_manifest.csv is missing")
  if (file.exists(manifest_path)) {
    manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE)
    assert(all(c("file", "sha256", "note") %in% names(manifest)), id,
           "input_manifest.csv schema is incomplete")
    if (all(c("file", "sha256") %in% names(manifest))) {
      for (i in seq_len(nrow(manifest))) {
        path <- file.path(dir, manifest$file[[i]])
        assert(file.exists(path), id, paste0("manifest file missing: ", manifest$file[[i]]))
        if (file.exists(path)) {
          assert(identical(sha256_file(path), manifest$sha256[[i]]), id,
                 paste0("manifest SHA mismatch: ", manifest$file[[i]]))
        }
      }
    }
  }
}

for (id in expected_ids[10:length(expected_ids)]) {
  assert(all(file.exists(file.path(model_dir(id), c("bet.reg_scaling", "bet.reg_scaling.full")))),
         id, "regional-scaling active and full audit files are required")
}
for (id in expected_ids[9:length(expected_ids)]) {
  assert(all(file.exists(file.path(model_dir(id), qc_files))), id,
         "size-data QC audit files are required from Step 09 onward")
}
for (id in expected_ids[1:8]) {
  assert(!any(file.exists(file.path(model_dir(id), qc_files))), id,
         "size-data QC appeared before Step 09")
}

## Helpers for MFCL INI/doitall semantics.
numeric_section <- function(path, label) {
  lines <- read_text(path)
  marker <- which(tolower(trimws(lines)) == paste0("# ", tolower(label)))
  if (length(marker) != 1L) return(NULL)
  comments <- which(seq_along(lines) > marker & grepl("^#", trimws(lines)))
  end <- if (length(comments)) comments[[1L]] - 1L else length(lines)
  block <- trimws(lines[seq.int(marker + 1L, end)])
  block <- block[nzchar(block) & !grepl("^#", block)]
  rows <- lapply(block, function(x) suppressWarnings(as.numeric(strsplit(x, "[[:space:]]+")[[1L]])))
  rows <- rows[vapply(rows, function(x) length(x) && all(is.finite(x)), logical(1))]
  if (!length(rows) || length(unique(lengths(rows))) != 1L) return(NULL)
  do.call(rbind, rows)
}

ini_version <- function(path) {
  lines <- trimws(read_text(path))
  data <- lines[nzchar(lines) & !startsWith(lines, "#")]
  suppressWarnings(as.integer(data[[1L]]))
}

parse_controls <- function(path) {
  lines <- read_text(path)
  result <- list()
  n <- 0L
  phase <- 0L
  for (line in lines) {
    start <- regmatches(line, regexec("<<PHASE([0-9]+)", line))[[1L]]
    if (length(start) == 2L) phase <- as.integer(start[[2L]])
    if (grepl("^PHASE[0-9]+(_[A-Z0-9_]+)?$", trimws(line))) phase <- 0L
    clean <- trimws(sub("#.*$", "", line))
    if (!nzchar(clean)) next
    words <- strsplit(clean, "[[:space:]]+")[[1L]]
    values <- suppressWarnings(as.numeric(words))
    if (length(values) < 3L) next
    for (offset in seq.int(1L, length(values) - 2L, by = 3L)) {
      triple <- values[offset:(offset + 2L)]
      if (all(is.finite(triple))) {
        n <- n + 1L
        result[[n]] <- data.frame(
          phase = phase, scope = as.integer(triple[[1L]]),
          flag = as.integer(triple[[2L]]), value = triple[[3L]]
        )
      }
    }
  }
  if (!length(result)) {
    return(data.frame(phase = integer(), scope = integer(), flag = integer(), value = numeric()))
  }
  do.call(rbind, result)
}

effective_flag <- function(controls, scope, flag, phase = Inf) {
  eligible <- controls$phase == 0L | controls$phase <= phase
  scoped <- controls[eligible & controls$scope == scope & controls$flag == flag, , drop = FALSE]
  if (!nrow(scoped)) {
    scoped <- controls[eligible & controls$scope == -999L & controls$flag == flag, , drop = FALSE]
  }
  if (!nrow(scoped)) return(NA_real_)
  tail(scoped$value, 1L)
}

age_m <- function(path) {
  age <- numeric_section(path, "age_pars")
  if (is.null(age) || nrow(age) < 5L) return(NA_real_)
  age[5L, 1L]
}

length_weight <- function(path) {
  values <- numeric_section(path, "Length-weight parameters")
  if (is.null(values)) numeric() else as.numeric(values)
}

frq_dimensions <- function(path) {
  lines <- read_text(path)
  marker <- grep("Number of[[:space:]]+Number of", lines)
  if (length(marker) != 1L) return(c(NA_integer_, NA_integer_))
  candidates <- lines[seq.int(marker + 1L, min(length(lines), marker + 5L))]
  candidates <- candidates[nzchar(trimws(candidates)) & !grepl("^#", trimws(candidates))]
  values <- suppressWarnings(as.integer(strsplit(trimws(candidates[[1L]]), "[[:space:]]+")[[1L]]))
  values[1:2]
}

controls_by_id <- setNames(lapply(expected_ids, function(id) {
  parse_controls(file.path(model_dir(id), "doitall.sh"))
}), expected_ids)

## Executable/INI compatibility and cumulative biology.
assert(ini_version(file.path(model_dir("01-Diag2023"), "bet.ini")) == 1003L,
       "01-Diag2023", "diagnostic reference must retain INI 1003")
for (id in expected_ids[-1L]) {
  assert(ini_version(file.path(model_dir(id), "bet.ini")) == 1007L,
         id, "Steps 02-19 must use INI 1007")
}
old_fisheries <- 33:41
old_penalty <- c(88, 53, 130, 109, 76, 93, 121, 77, 23)
new_cv <- c(24, 31, 20, 21, 26, 23, 20, 25, 47)
for (i in seq_along(old_fisheries)) {
  assert(effective_flag(controls_by_id[["01-Diag2023"]], -old_fisheries[[i]], 92L, 1L) ==
           old_penalty[[i]], "01-Diag2023", "archived flag-92 penalty vector changed")
  assert(effective_flag(controls_by_id[["02-NewExeIni1007"]], -old_fisheries[[i]], 92L, 1L) ==
           new_cv[[i]], "02-NewExeIni1007", "2.2.7.9 flag-92 CV vector changed")
}
assert(effective_flag(controls_by_id[["01-Diag2023"]], 2L, 128L, 1L) == 10,
       "01-Diag2023", "old executable initial-Z scaling must be 10")
assert(effective_flag(controls_by_id[["02-NewExeIni1007"]], 2L, 128L, 1L) == 100,
       "02-NewExeIni1007", "new executable initial-Z scaling must be 100")
for (id in expected_ids[-1L]) {
  script <- paste(read_text(file.path(model_dir(id), "doitall.sh")), collapse = "\n")
  assert(grepl(
    "regional_recruitment_penalty=${REGIONAL_RECRUITMENT_PENALTY:-0.1}",
    script, fixed = TRUE
  ) && grepl(
    "2 110 $regional_recruitment_penalty_flag",
    script, fixed = TRUE
  ), id, "the final-exploration regional-recruitment penalty default/control is missing")
}

expected_m <- -2.54930339768360
for (id in expected_ids[1:2]) {
  assert(effective_flag(controls_by_id[[id]], 1L, 121L, 1L) == 1,
         id, "natural-mortality scaling must remain estimated before Step 03")
}
for (id in expected_ids[3:length(expected_ids)]) {
  assert(isTRUE(all.equal(age_m(file.path(model_dir(id), "bet.ini")), expected_m,
                          tolerance = 1e-12)), id,
         "fixed Lorenzen natural-mortality intercept changed")
  assert(effective_flag(controls_by_id[[id]], 1L, 121L, 1L) == 0,
         id, "natural mortality is not fixed with parest flag 121=0")
}
expected_lw <- c(3.073533e-05, 2.932410)
for (id in expected_ids[4:length(expected_ids)]) {
  assert(isTRUE(all.equal(length_weight(file.path(model_dir(id), "bet.ini")),
                          expected_lw, tolerance = 1e-12)),
         id, "BET 2026 length-weight parameters changed")
}
for (id in expected_ids[5:length(expected_ids)]) {
  assert(identical(frq_dimensions(file.path(model_dir(id), "bet.frq")), c(5L, 33L)),
         id, "five-region/33-fishery FRQ structure changed")
}

## Size-data rules.
f15 <- utils::read.csv(file.path(model_dir("09-SizeDataQC"), "f15-lf-qc-summary.csv"))
dom <- utils::read.csv(file.path(model_dir("09-SizeDataQC"), "dom-lf-qc-summary.csv"))
assert(nrow(f15) == 1L && f15$lf_rows == 135L && f15$affected_rows == 66L &&
         f15$removed_count == 1057L && !f15$renormalised &&
         !f15$catch_or_effort_changed, "09-SizeDataQC",
       "F15 <70 cm audit does not match the agreed treatment")
assert(identical(as.integer(dom$fishery), 21:23) &&
         identical(as.integer(dom$removed_count), c(56L, 6146L, 1702L)) &&
         sum(dom$empty_rows_removed) == 1L && !any(dom$renormalised) &&
         !any(dom$catch_or_effort_changed), "09-SizeDataQC",
       "F21-F23 >90 cm audit does not match the agreed treatment")
for (id in expected_ids[9:length(expected_ids)]) {
  controls <- controls_by_id[[id]]
  assert(effective_flag(controls, -14L, 75L, 1L) == 5 &&
           effective_flag(controls, -15L, 75L, 1L) == 5,
         id, "F14 and F15 must both fix the youngest five selectivity ages")
}

## Regional CPUE and headerless v2.5 scaling.
for (id in expected_ids[10:length(expected_ids)]) {
  active <- file.path(model_dir(id), "bet.reg_scaling")
  lines <- trimws(read_text(active))
  values <- lapply(lines[nzchar(lines)], function(x) {
    suppressWarnings(as.numeric(strsplit(x, "[[:space:]]+")[[1L]]))
  })
  assert(length(values) == 20L && all(lengths(values) == 5L) &&
           all(vapply(values, function(x) all(is.finite(x)), logical(1))),
         id, "v2.5 bet.reg_scaling must be a headerless 20x5 numeric matrix")
  assert(identical(sha256_file(active),
                   "5f047ddb4053d1f6df9ace18e85e440b11553de246d024ce8138b427f5f9f7e3"),
         id, "active regional-scaling matrix changed")
  for (flag in c(77L, 78L, 79L, 80L, 81L)) {
    expected <- c(`77` = 100, `78` = 1, `79` = 240, `80` = 220, `81` = 1)[as.character(flag)]
    assert(effective_flag(controls_by_id[[id]], 1L, flag, 5L) == expected,
           id, paste0("regional-scaling control ", flag, " changed"))
  }
}
for (id in expected_ids[11:length(expected_ids)]) {
  for (fishery in 29:33) {
    assert(effective_flag(controls_by_id[[id]], -fishery, 66L, 1L) == 1,
           id, "time-varying CPUE CV flag 66 is not active for all five indices")
  }
}
for (id in expected_ids[12:length(expected_ids)]) {
  for (i in seq_along(29:33)) {
    assert(effective_flag(controls_by_id[[id]], -(29:33)[[i]], 92L, 1L) ==
             c(35, 24, 21, 24, 23)[[i]], id,
           "regional CPUE observation-error SD controls changed")
  }
}

## CAAL variants.
age_hashes <- c(
  "13-NewAgeData" = "e7f591cb39b08a7b381b5e322331d5a4ca17e30008e8b976ae1b73e9111f655d",
  "14a-REG075" = "83e66c115df9ec2adabea262c650716dc711ad7ca9e1fdb98a5675778ee0ad74",
  "14b-SUB075" = "426859b825bd815aa69c8d97c9dd93097027ed1eb6b9e444d88b69562097a00c"
)
for (id in names(age_hashes)) {
  assert(identical(sha256_file(file.path(model_dir(id), "bet.age_length")), age_hashes[[id]]),
         id, "CAAL source variant changed")
}
for (id in expected_ids[15:length(expected_ids)]) {
  assert(identical(sha256_file(file.path(model_dir(id), "bet.age_length")),
                   age_hashes[["14b-SUB075"]]), id,
         "selected SUB075 CAAL input was not carried forward")
}

## Exact Job 18718 flexible-selectivity signature.
selectivity_signature <- function(path) {
  lines <- read_text(path)
  phase <- -1L
  rows <- character()
  flags <- c(3L, 16L, 24L, 26L, 56L, 57L, 61L, 75L)
  for (line in lines) {
    marker <- regmatches(line, regexec("^#  PHASE ([0-9]+)", line))[[1L]]
    if (length(marker) == 2L) phase <- as.integer(marker[[2L]])
    if (!phase %in% c(1L, 5L)) next
    words <- strsplit(trimws(sub("#.*$", "", line)), "[[:space:]]+")[[1L]]
    values <- suppressWarnings(as.integer(words))
    if (length(values) < 3L) next
    for (offset in seq.int(1L, length(values) - 2L, by = 3L)) {
      triple <- values[offset:(offset + 2L)]
      if (all(is.finite(triple)) && triple[[1L]] >= -999L &&
          triple[[1L]] <= -1L && triple[[2L]] %in% flags) {
        rows <- c(rows, paste(c(phase, triple), collapse = ","))
      }
    }
  }
  paste0(paste(rows, collapse = "\n"), "\n")
}
expected_selectivity_sha <- "def9bf5fecf1a6e7e5890a8ea9ff2fcc577442334510c8409836bd43caa00400"
for (id in expected_ids[16:20]) {
  signature <- selectivity_signature(file.path(model_dir(id), "doitall.sh"))
  assert(length(strsplit(trimws(signature), "\n")[[1L]]) == 94L, id,
         "flexible-selectivity signature must contain 94 Phase 1/5 controls")
  assert(identical(sha256_text(signature), expected_selectivity_sha), id,
         "flexible-selectivity update differs from Job 18718")
}

job19325_signature <- selectivity_signature(
  file.path(model_dir("20-F10NDWeak"), "doitall.sh")
)
assert(length(strsplit(trimws(job19325_signature), "\n")[[1L]]) == 96L,
       "20-F10NDWeak",
       "Job 19325 selectivity signature must add exactly the two F10 penalty controls")
assert(identical(
  sha256_text(job19325_signature),
  "7107b30b5b9bbf5ef96ae3700322744ee40431cb61fa29f4f454b9c7ca0cb311"
), "20-F10NDWeak", "selectivity controls differ from the deterministic Job 19325 treatment")
assert(!isTRUE(effective_flag(controls_by_id[["19-DMG8Nmax25"]], -10L, 16L, 1L) == 1),
       "19-DMG8Nmax25", "F10 non-decreasing penalty appeared before Step 20")
assert(effective_flag(controls_by_id[["20-F10NDWeak"]], -10L, 16L, 1L) == 1 &&
         effective_flag(controls_by_id[["20-F10NDWeak"]], -10L, 56L, 1L) == 10000,
       "20-F10NDWeak", "F10 flags 16=1 and 56=10000 are not both active")

## Tag mixing and reporting-rate isolation.
rr_labels <- c(
  "tag fish rep", "tag fish rep group flags", "tag_fish_rep active flags",
  "tag_fish_rep target", "tag_fish_rep penalty"
)
rr_signature <- function(id) {
  ini <- file.path(model_dir(id), "bet.ini")
  paste(vapply(rr_labels, function(label) {
    matrix <- numeric_section(ini, label)
    if (is.null(matrix)) return("MISSING")
    paste(format(as.numeric(matrix), digits = 16L, scientific = FALSE, trim = TRUE),
          collapse = ",")
  }, character(1)), collapse = "|")
}
rr_reference_2023 <- rr_signature("05-NewStructure")
for (id in expected_ids[5:7]) {
  assert(identical(rr_signature(id), rr_reference_2023), id,
         "2023 reporting-rate matrices drifted before the data update")
}
rr_reference_2026 <- rr_signature("08-DataTo2024")
for (id in expected_ids[8:length(expected_ids)]) {
  assert(identical(rr_signature(id), rr_reference_2026), id,
         "2026 reporting-rate means/groups/active flags/targets/penalties drifted")
}
tag_flags <- lapply(expected_ids, function(id) {
  numeric_section(file.path(model_dir(id), "bet.ini"), "tag flags")
})
names(tag_flags) <- expected_ids
for (id in expected_ids[5:16]) {
  assert(all(tag_flags[[id]][, 2L] == 0), id,
         "tag reporting exclusion appeared before Step 17")
}
assert(length(unique(tag_flags[["16-MIX020"]][, 1L])) > 1L,
       "16-MIX020", "K=0.20 release-specific mixing periods are absent")
assert(all(tag_flags[["16-MIX020"]][, 2L] == 0),
       "16-MIX020", "Step 16 must retain reporting rates during pre-mixing windows")
for (id in expected_ids[18:length(expected_ids)]) {
  assert(all(tag_flags[[id]][, 2L] == 1), id,
         "tag_flags(:,2) must be one from Step 17 onward")
  assert(identical(tag_flags[[id]][, 1L], tag_flags[["16-MIX020"]][, 1L]),
         id, "K=0.20 mixing periods were not carried forward")
}

## Negative-binomial tau treatment is the original 2023 treatment throughout.
for (id in expected_ids) {
  controls <- controls_by_id[[id]]
  assert(effective_flag(controls, 1L, 111L, 1L) == 4, id,
         "tag likelihood is not negative binomial")
  assert(effective_flag(controls, -999L, 43L, 1L) == 0 &&
           effective_flag(controls, -999L, 44L, 1L) == 0, id,
         "tag tau estimation was activated")
}

## Step 20: Job 19325 deterministic target; Step 19 DM controls retained.
final_id <- "20-F10NDWeak"
final_controls <- controls_by_id[[final_id]]
for (pair in list(c(1L, 141L, 11), c(1L, 320L, 5), c(1L, 342L, 25),
                  c(-999L, 69L, 0))) {
  assert(effective_flag(final_controls, pair[[1L]], pair[[2L]], 1L) == pair[[3L]],
         final_id, paste0("required DM control ", pair[[1L]], "/", pair[[2L]], " changed"))
}
expected_g8 <- c(1, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 3, 7, 6, 6, 7, 3,
                 3, 4, 5, 7, 7, 7, 7, 4, 4, 5, 5, 8, 8, 8, 8, 8)
for (fishery in 1:33) {
  assert(effective_flag(final_controls, -fishery, 68L, 1L) == expected_g8[[fishery]],
         final_id, paste0("G8 assignment changed for F", fishery))
}
assert(effective_flag(final_controls, -999L, 89L, 1L) == 0 &&
         effective_flag(final_controls, -999L, 89L, 2L) == 1,
       final_id, "fish_pars(23) must be fixed in Phase 1 and estimated from Phase 2")
final_script <- paste(read_text(file.path(model_dir(final_id), "doitall.sh")), collapse = "\n")
assert(grepl("dm_concentration=7", final_script, fixed = TRUE) &&
         grepl("fish_row == 22", final_script, fixed = TRUE) &&
         grepl("00.dm-fixed.par", final_script, fixed = TRUE),
       final_id, "fish_pars row 22 is not explicitly written and fixed at 7 before Phase 1")
assert(effective_flag(final_controls, 1L, 313L, 1L) == 0,
       final_id, "normal-likelihood 1% tail compression must remain off under DM")
assert(!grepl("jitter|perturb|seed[ _-]*23", final_script, ignore.case = TRUE),
       final_id, "deterministic Step 20 must not execute a jitter, perturbation, or seed-23 path")

## Every transition changes only its declared axis.
compare_transition <- function(from, to, allowed) {
  changed <- character()
  for (file in core_files) {
    a <- file.path(model_dir(from), file)
    b <- file.path(model_dir(to), file)
    if (file.exists(a) != file.exists(b) ||
        (file.exists(a) && !identical(sha256_file(a), sha256_file(b)))) {
      changed <- c(changed, file)
    }
  }
  assert(setequal(changed, allowed), paste0(from, " -> ", to),
         paste0("changed core files are `", paste(changed, collapse = ", "),
                "`; expected `", paste(allowed, collapse = ", "), "`"))
}
transitions <- list(
  c("01-Diag2023", "02-NewExeIni1007", "bet.ini,doitall.sh,tag_rep_map.R"),
  c("02-NewExeIni1007", "03-FixM", "bet.ini,doitall.sh"),
  c("03-FixM", "04-LengthWeight", "bet.ini"),
  c("04-LengthWeight", "05-NewStructure",
    "bet.frq,bet.ini,bet.tag,bet.age_length,doitall.sh,fishery_map.R,tag_rep_map.R"),
  c("05-NewStructure", "06-ConvertToLength", "bet.frq"),
  c("06-ConvertToLength", "07-AddLengthData", "bet.frq"),
  c("07-AddLengthData", "08-DataTo2024", "bet.frq,bet.ini,bet.tag,tag_rep_map.R"),
  c("08-DataTo2024", "09-SizeDataQC", "bet.frq,doitall.sh"),
  c("09-SizeDataQC", "10-RegionalCPUE",
    "bet.frq,doitall.sh,bet.reg_scaling,bet.reg_scaling.full"),
  c("10-RegionalCPUE", "11-TimeVaryingCV", "doitall.sh"),
  c("11-TimeVaryingCV", "12-CPUEErrorCalibration", "doitall.sh"),
  c("12-CPUEErrorCalibration", "13-NewAgeData", "bet.age_length"),
  c("13-NewAgeData", "14a-REG075", "bet.age_length"),
  c("13-NewAgeData", "14b-SUB075", "bet.age_length"),
  c("14b-SUB075", "15-SelectivityUpdate", "doitall.sh,fishery_map.R"),
  c("15-SelectivityUpdate", "16-MIX020", "bet.ini"),
  c("16-MIX020", "17-TagReportingExclusion", "bet.ini"),
  c("17-TagReportingExclusion", "18-EffortCreep", "bet.frq"),
  c("18-EffortCreep", "19-DMG8Nmax25", "doitall.sh"),
  c("19-DMG8Nmax25", "20-F10NDWeak", "doitall.sh")
)
for (transition in transitions) {
  compare_transition(
    transition[[1L]], transition[[2L]],
    strsplit(transition[[3L]], ",", fixed = TRUE)[[1L]]
  )
}

## The Step 15 map may change selectivity metadata, but never fishery identity.
read_fishery_map <- function(step_id) {
  env <- new.env(parent = baseenv())
  sys.source(file.path(model_dir(step_id), "fishery_map.R"), envir = env)
  env$fishery_map
}
expected_five_region_names <- c(
  "01.LL.WEST.ALL.1", "02.LL.EAST.ALL.1", "03.LL.US.1",
  "04.LL.ALL.2", "05.LL.OS.2", "06.LL.ARCH.3", "07.LL.WEST.3",
  "08.LL.EAST.4", "09.LL.OS.3", "10.LL.ALL.5", "11.LL.AU.5",
  "12.PS.JP.1", "13.PL.JP.1", "14.HL.ID.2", "15.HL.PH.2",
  "16.PL.ALL.2", "17.PS.ID.2", "18.PS.PH.2", "19.PS.ASS.2",
  "20.PS.UNA.2", "21.DOM.ID.2", "22.DOM.PH.2", "23.DOM.VN.2",
  "24.PL.ALL.WEST.3", "25.PS.ASSOC.WEST.3", "26.PS.ASSOC.EAST.4",
  "27.PS.UNASSOC.WEST.3", "28.PS.UNASSOC.EAST.4",
  paste0(sprintf("%02d", 29:33), ".Index R", 1:5)
)
expected_five_region_regions <- c(
  1L, 1L, 1L, 2L, 2L, 3L, 3L, 4L, 3L, 5L, 5L,
  1L, 1L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L,
  3L, 3L, 4L, 3L, 4L, 1L, 2L, 3L, 4L, 5L
)
five_region_steps <- expected_ids[
  match("05-NewStructure", expected_ids):length(expected_ids)
]
base_map <- read_fishery_map("05-NewStructure")
assert(identical(base_map$fishery_name, expected_five_region_names),
       "05-NewStructure", "fishery display names differ from the approved 2026 map")
assert(identical(base_map$fishery, seq_len(33L)),
       "05-NewStructure", "fishery IDs differ from the approved 2026 map")
assert(identical(as.integer(base_map$region), expected_five_region_regions),
       "05-NewStructure", "fishery regions differ from the approved 2026 map")
identity_fields <- c(
  "fishery_name", "fishery", "region", "group", "source_recipe",
  "tag_recapture_group", "tag_recapture_name"
)
for (step_id in five_region_steps) {
  current_map <- read_fishery_map(step_id)
  assert(
    identical(current_map[identity_fields], base_map[identity_fields]),
    step_id,
    "fishery identity or tag-recapture metadata changed after Step 05"
  )
}

## Final static inputs match Jobs 18718 and 19325; Step 20 changes only doitall flags.
job18718_aligned_hashes <- c(
  "bet.frq" = "9b8f4630b5b8bec8b8292e8207cc789b00542d29338faf6187f3c9af55504aa3",
  "bet.ini" = "5292938d4743c1dfdd2f1a095c1aa87482c9c17f78b8d879671fe6851d58646f",
  "bet.tag" = "b140e66eb52f2b7e022ef2c562134f8bc9baf3dede18ce95283a001acd2b013f",
  "bet.age_length" = "426859b825bd815aa69c8d97c9dd93097027ed1eb6b9e444d88b69562097a00c",
  "bet.reg_scaling" = "5f047ddb4053d1f6df9ace18e85e440b11553de246d024ce8138b427f5f9f7e3",
  "mfcl.cfg" = "2ec8a291fae62c6f37541aec1de37444626d42b3290b371bb42b63d510034eae",
  "tag_rep_map.R" = "96bdd0e9e75bc0794036385edc08e7219942d3c23fe4839be5986c4d77f96085",
  "fishery_map.R" = "af75e51bed5fcbc752aa1a2534ef7c742daee88048a964e7e9e4b91223118717"
)
for (file in names(job18718_aligned_hashes)) {
  assert(identical(sha256_file(file.path(model_dir(final_id), file)),
                   job18718_aligned_hashes[[file]]), final_id,
         paste0(file, " differs from the locked Job 18718/19325-aligned target"))
}

if (length(failures)) {
  cat("Validation failed:\n", paste0(" - ", failures, collapse = "\n"), "\n", sep = "")
  quit(status = 1L)
}

cat(
  "Validated 21 frozen models / 20 cumulative steps.\n",
  "Final: deterministic Job 19325 treatment; Job 18718 plus only F10 flags ",
  "16=1 and 56=10000; no jitter or promoted seed; DM G8 Nmax25 retained.\n",
  "Runtime: Suva, immutable tuna-flow v2.5, pinned mfclkit/mfclshiny.\n",
  sep = ""
)
