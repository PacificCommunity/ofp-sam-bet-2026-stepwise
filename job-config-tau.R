# Kflow registration view for the common-tau campaign.
# Each selectivity/recruitment row is crossed at launch with common-tau native
# and lower-2 bounds plus a three-stratum programme-informed recapture-fishery
# configuration, regional recruitment coefficients 0.1 and 0.2, and fixed
# versus Phase 11-12 estimated M. OPR rows additionally use Nmax 25 or default.
source("job-config.R", local = TRUE)
stepwise_models <- stepwise_models[
  stepwise_models$step_id %in% c(
    "S03-CommonTagTau-MIX015",
    "S04-CommonTagTauSpline-MIX015",
    "S05-CommonTagTauOPR-MIX015",
    "S06-CommonTagTauSplineOPR-MIX015"
  ),
  ,
  drop = FALSE
]
