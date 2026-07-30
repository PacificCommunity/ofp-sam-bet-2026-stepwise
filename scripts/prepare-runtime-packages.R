spec_text <- Sys.getenv(
  "KFLOW_REPO_RUNTIME_PACKAGES",
  Sys.getenv("KFLOW_RUNTIME_PACKAGES", "")
)
if (!nzchar(spec_text) || tolower(spec_text) %in% c("none", "never", "false", "off")) {
  stop(
    "BUILD_MODEL_PAYLOAD requires exact KFLOW_REPO_RUNTIME_PACKAGES pins.",
    call. = FALSE
  )
}

parts <- trimws(strsplit(spec_text, ",", fixed = TRUE)[[1L]])
parts <- parts[nzchar(parts)]
specs <- lapply(parts, function(part) {
  fields <- strsplit(part, "=", fixed = TRUE)[[1L]]
  if (length(fields) != 2L) {
    stop("Invalid runtime package specification: ", part, call. = FALSE)
  }
  repo_ref <- strsplit(fields[[2L]], "@", fixed = TRUE)[[1L]]
  if (length(repo_ref) != 2L || !grepl("^[0-9a-f]{40}$", repo_ref[[2L]])) {
    stop("Runtime package refs must be exact 40-character SHAs: ", part, call. = FALSE)
  }
  list(
    package = trimws(fields[[1L]]),
    repo = trimws(repo_ref[[1L]]),
    ref = tolower(trimws(repo_ref[[2L]]))
  )
})

required <- c("mfclkit", "mfclshiny")
package_names <- vapply(specs, `[[`, character(1L), "package")
missing_specs <- setdiff(required, package_names)
if (length(missing_specs)) {
  stop(
    "Missing required runtime package pin(s): ",
    paste(missing_specs, collapse = ", "),
    call. = FALSE
  )
}

ref_env <- c(
  mfclkit = "MFCLKIT_GITHUB_REF",
  mfclshiny = "MFCLSHINY_GITHUB_REF"
)
for (index in seq_along(specs)) {
  package <- specs[[index]]$package
  env_name <- if (package %in% names(ref_env)) unname(ref_env[[package]]) else NULL
  if (is.null(env_name)) next
  override <- trimws(Sys.getenv(env_name, ""))
  if (nzchar(override)) specs[[index]]$ref <- tolower(override)
  if (!grepl("^[0-9a-f]{40}$", specs[[index]]$ref)) {
    stop(env_name, " must be a full 40-character Git commit SHA.", call. = FALSE)
  }
}

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
preferred <- Sys.getenv(
  "R_LIBS_USER",
  Sys.getenv("KFLOW_RUNTIME_LIBRARY", file.path(root, ".R-library"))
)
if (!nzchar(preferred)) preferred <- file.path(root, ".R-library")
dir.create(preferred, recursive = TRUE, showWarnings = FALSE)
if (file.access(preferred, 2L) != 0L) {
  preferred <- file.path(root, ".R-library")
  dir.create(preferred, recursive = TRUE, showWarnings = FALSE)
}
Sys.setenv(R_LIBS_USER = preferred, KFLOW_RUNTIME_LIBRARY = preferred)
.libPaths(unique(c(preferred, .libPaths())))

description_field <- function(package, field) {
  description <- tryCatch(
    suppressWarnings(utils::packageDescription(package, lib.loc = preferred)),
    error = function(e) NULL
  )
  if (is.null(description) || !(field %in% names(description))) return("")
  value <- description[[field]]
  if (is.null(value) || !length(value) || is.na(value[[1L]])) "" else {
    as.character(value[[1L]])
  }
}

matches_ref <- function(spec) {
  identical(tolower(description_field(spec$package, "RemoteSha")), spec$ref)
}

if (!requireNamespace("remotes", quietly = TRUE)) {
  utils::install.packages(
    "remotes",
    lib = preferred,
    repos = "https://cloud.r-project.org",
    dependencies = TRUE
  )
}

token <- ""
for (name in c(
  "GITHUB_PAT", "GIT_PAT", "GITHUB_TOKEN", "GH_TOKEN",
  "KFLOW_GITHUB_TOKEN", "KFLOW_PERSONAL_TOKEN"
)) {
  value <- Sys.getenv(name, "")
  if (nzchar(value)) {
    token <- value
    break
  }
}

for (spec in specs) {
  if (matches_ref(spec)) next
  message(
    "[final-exploration] Installing ",
    spec$package, " from ", spec$repo, "@", spec$ref
  )
  remotes::install_github(
    repo = spec$repo,
    ref = spec$ref,
    lib = preferred,
    dependencies = NA,
    upgrade = "never",
    auth_token = if (nzchar(token)) token else NULL,
    quiet = FALSE
  )
  if (!matches_ref(spec)) {
    stop(
      spec$package, " was not installed at the requested SHA ",
      spec$ref, ".",
      call. = FALSE
    )
  }
}

if (!all(vapply(required, requireNamespace, logical(1L), quietly = TRUE))) {
  stop("mfclkit and mfclshiny must both be available.", call. = FALSE)
}
