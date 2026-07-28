## Two independent doitall fits using the verified Joe mixing vectors and
## estimating the Lorenzen natural-mortality intercept in Phases 11-12.
source("job-config-job17805-joe-regionmean.R", local = TRUE)

stepwise_models$step_id <- c(
  "F14-Y5-REC01-JOE-K015-ESTM",
  "F14-Y5-REC01-JOE-K020-ESTM"
)
stepwise_models$STEP_SELECT <- stepwise_models$step_id
stepwise_models$major_step <- rep(
  "Job17805JoeRegionMeanMixingEstimateM", 2
)
stepwise_models$substep <- c(
  "JoeRegionMean-K015-EstimateM",
  "JoeRegionMean-K020-EstimateM"
)
stepwise_models$change_axis <- c(
  paste(
    "Independent doitall from the frozen Job 17805 source inputs.",
    "Replace only tag_flags(:,1) with the SC22-IP10 K=0.15 vector using",
    "Joe's all-region mean for Region 1; set the INI Lorenzen M-intercept",
    "start to -3 and estimate it in Phases 11-12."
  ),
  paste(
    "Independent doitall from the frozen Job 17805 source inputs.",
    "Replace only tag_flags(:,1) with the SC22-IP10 K=0.20 vector;",
    "Joe's Region-1 mean is 2 at this cutoff; set the INI Lorenzen",
    "M-intercept start to -3 and estimate it in Phases 11-12."
  )
)
stepwise_models$control_notes <- rep(
  paste(
    "Start from -makepar, not a previous PAR. Retain F15 <70 cm and DOM",
    "midpoint >90 cm exclusions, F14/F15 youngest-five-age controls,",
    "standard recruitment, rec penalty 0.1, movement prior 0.1, Nmax=25,",
    "and common estimated tag tau. Set age_pars(5) intercept to -3, then",
    "estimate that one Lorenzen M intercept only in Phases 11-12;",
    "retain MGC 1e-4."
  ),
  2
)
stepwise_models$model_label <- c(
  "Job 17805 controls | Joe all-region mean | K=0.15 | estimate M",
  "Job 17805 controls | Joe all-region mean | K=0.20 | estimate M"
)
stepwise_models$job_title <- c(
  "01. Joe region mean | K=0.15 | doitall | estimate M",
  "02. Joe region mean | K=0.20 | doitall | estimate M"
)
stepwise_models$job_key <- c(
  "job17805-joe-regionmean-k015-estm",
  "job17805-joe-regionmean-k020-estm"
)
stepwise_models$estimate_m_final <- rep("true", 2)
stepwise_models$m_start_intercept <- rep("-3", 2)

stepwise_run$flow_group <-
  "bet-2026-job17805-joe-regionmean-k015-k020-estm-20260729"
stepwise_run$default_step_select <- stepwise_models$step_id[[1L]]
