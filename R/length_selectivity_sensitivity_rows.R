## Length-based selectivity sensitivity rows for the experiment branch.
##
## These rows intentionally share the Step 13 model source. Each step folder
## contains only a patch.R file that appends a documented option block to the
## staged doitall.sh at runtime.

length_selectivity_sensitivity_specs <- function() {
  fish <- function(ids, flag, value) {
    lapply(ids, function(id) c(scope = as.integer(-id), flag = as.integer(flag), value = as.integer(value)))
  }
  fish_many <- function(ids, values, flag) {
    stopifnot(length(ids) == length(values))
    unname(Map(function(id, value) c(scope = as.integer(-id), flag = as.integer(flag), value = as.integer(value)), ids, values))
  }
  global <- function(flag, value) {
    list(c(scope = -999L, flag = as.integer(flag), value = as.integer(value)))
  }
  parest <- function(flag, value) {
    list(c(scope = 1L, flag = as.integer(flag), value = as.integer(value)))
  }
  flags <- function(...) {
    unlist(list(...), recursive = FALSE)
  }

  ll <- 1:11
  idx <- 29:33
  dome_all <- c(12, 13, 16:28)
  dome_low <- c(16, 17, 18, 21, 22, 23, 24)
  dome_dom_pl <- c(16, 21, 22, 23, 24)
  dome_ps <- c(12, 13, 17, 18, 19, 20, 25, 26, 27, 28)
  ps_pl_dom <- c(12, 13, 16:28)
  ll_young_zero <- c(2, 4, 5, 7, 8, 9, 10)

  list(
    list(
      step_id = "13b-LBS-N3",
      substep = "13b",
      label = "LBS N3",
      key = "13b-lbs-n3",
      change = "length-based selectivity with 3 cubic-spline nodes",
      notes = "Reduces length-based spline flexibility from the Step 13 baseline of 5 nodes.",
      edits = flags(global(61, 3))
    ),
    list(
      step_id = "13c-LBS-N4",
      substep = "13c",
      label = "LBS N4",
      key = "13c-lbs-n4",
      change = "length-based selectivity with 4 cubic-spline nodes",
      notes = "Moderate node reduction between the 3-node and 5-node cases.",
      edits = flags(global(61, 4))
    ),
    list(
      step_id = "13d-LBS-N6",
      substep = "13d",
      label = "LBS N6",
      key = "13d-lbs-n6",
      change = "length-based selectivity with 6 cubic-spline nodes",
      notes = "Increases flexibility to test whether the baseline depletion shift is a low-node artifact.",
      edits = flags(global(61, 6))
    ),
    list(
      step_id = "13e-LBS-IDXmono-N5",
      substep = "13e",
      label = "LBS IDXmono N5",
      key = "13e-lbs-idxmono-n5",
      change = "baseline 5-node length-based selectivity with non-decreasing index selectivity",
      notes = "Applies the monotone penalty to the five index fisheries only.",
      edits = flags(global(61, 5), fish(idx, 16, 1))
    ),
    list(
      step_id = "13f-LBS-IDXmono-N4",
      substep = "13f",
      label = "LBS IDXmono N4",
      key = "13f-lbs-idxmono-n4",
      change = "4-node length-based selectivity with non-decreasing index selectivity",
      notes = "Combines moderate smoothing with monotone survey/index selectivity.",
      edits = flags(global(61, 4), fish(idx, 16, 1))
    ),
    list(
      step_id = "13g-LBS-IDXmono-N3",
      substep = "13g",
      label = "LBS IDXmono N3",
      key = "13g-lbs-idxmono-n3",
      change = "3-node length-based selectivity with non-decreasing index selectivity",
      notes = "Strongly smooths the length spline while keeping index selectivity monotone.",
      edits = flags(global(61, 3), fish(idx, 16, 1))
    ),
    list(
      step_id = "13h-LBS-LLmono-N4",
      substep = "13h",
      label = "LBS LLmono N4",
      key = "13h-lbs-llmono-n4",
      change = "4-node length-based selectivity with non-decreasing longline selectivity",
      notes = "Strong diagnostic: longline gears can be asymptotic, but dome-shaped targeting is also plausible.",
      edits = flags(global(61, 4), fish(ll, 16, 1))
    ),
    list(
      step_id = "13i-LBS-LLIDXmono-N4",
      substep = "13i",
      label = "LBS LL+IDXmono N4",
      key = "13i-lbs-llidxmono-n4",
      change = "4-node length-based selectivity with non-decreasing longline and index selectivity",
      notes = "Strong diagnostic for whether large-fish selectivity tails are driving the depletion shift.",
      edits = flags(global(61, 4), fish(c(ll, idx), 16, 1))
    ),
    list(
      step_id = "13j-LBS-LLIDXmono-N3",
      substep = "13j",
      label = "LBS LL+IDXmono N3",
      key = "13j-lbs-llidxmono-n3",
      change = "3-node length-based selectivity with non-decreasing longline and index selectivity",
      notes = "Strongest smoothing plus monotone large-fish signal diagnostic.",
      edits = flags(global(61, 3), fish(c(ll, idx), 16, 1))
    ),
    list(
      step_id = "13k-LBS-LLIDXmono-N5",
      substep = "13k",
      label = "LBS LL+IDXmono N5",
      key = "13k-lbs-llidxmono-n5",
      change = "baseline 5-node length-based selectivity with non-decreasing longline and index selectivity",
      notes = "Separates monotone-tail effects from node-count effects.",
      edits = flags(global(61, 5), fish(c(ll, idx), 16, 1))
    ),
    list(
      step_id = "13l-LBS-LLIDXsoft-N4",
      substep = "13l",
      label = "LBS LL+IDX soft mono N4",
      key = "13l-lbs-llidxsoft-n4",
      change = "4-node non-decreasing longline/index selectivity with a softer monotone penalty",
      notes = "Uses fish flag 56 = 100000 for the monotone fisheries instead of the source default 1000000.",
      edits = flags(global(61, 4), fish(c(ll, idx), 16, 1), fish(c(ll, idx), 56, 100000))
    ),
    list(
      step_id = "13m-LBS-LLIDXvsoft-N4",
      substep = "13m",
      label = "LBS LL+IDX very soft mono N4",
      key = "13m-lbs-llidxvsoft-n4",
      change = "4-node non-decreasing longline/index selectivity with a very soft monotone penalty",
      notes = "Uses fish flag 56 = 10000 for the monotone fisheries.",
      edits = flags(global(61, 4), fish(c(ll, idx), 16, 1), fish(c(ll, idx), 56, 10000))
    ),
    list(
      step_id = "13n-LBS-NoDome-N4",
      substep = "13n",
      label = "LBS no dome N4",
      key = "13n-lbs-nodome-n4",
      change = "4-node length-based selectivity with Step 13 dome/terminal-zero constraints removed",
      notes = "Sets fish flag 16 back to 0 for the fisheries that inherited 16 = 2 constraints.",
      edits = flags(global(61, 4), fish(dome_all, 16, 0), fish(dome_all, 3, 37))
    ),
    list(
      step_id = "13o-LBS-RelaxLowDome-N4",
      substep = "13o",
      label = "LBS relax low dome N4",
      key = "13o-lbs-relax-low-dome-n4",
      change = "4-node length-based selectivity with low terminal-zero cutoffs relaxed",
      notes = "Raises the most restrictive 16 = 2 cutoff ages to 20 quarters.",
      edits = flags(global(61, 4), fish(dome_low, 3, 20))
    ),
    list(
      step_id = "13p-LBS-RelaxDOMPL-N4",
      substep = "13p",
      label = "LBS relax DOM/PL N4",
      key = "13p-lbs-relax-dompl-n4",
      change = "4-node length-based selectivity with DOM/PL terminal-zero cutoffs relaxed",
      notes = "Targets the DOM/PL low-age terminal-zero constraints only.",
      edits = flags(global(61, 4), fish(dome_dom_pl, 3, 20))
    ),
    list(
      step_id = "13q-LBS-RelaxPS-N4",
      substep = "13q",
      label = "LBS relax PS N4",
      key = "13q-lbs-relax-ps-n4",
      change = "4-node length-based selectivity with PS and JP terminal-zero cutoffs relaxed",
      notes = "Raises the PS/JP 16 = 2 cutoffs to 30 quarters.",
      edits = flags(global(61, 4), fish(dome_ps, 3, 30))
    ),
    list(
      step_id = "13r-LBS-DomeMid-N4",
      substep = "13r",
      label = "LBS dome mid N4",
      key = "13r-lbs-dome-mid-n4",
      change = "4-node length-based selectivity with a common mid terminal-zero cutoff",
      notes = "Sets all inherited 16 = 2 cutoff ages to 25 quarters.",
      edits = flags(global(61, 4), fish(dome_all, 3, 25))
    ),
    list(
      step_id = "13s-LBS-NoLowDome-IDX-N4",
      substep = "13s",
      label = "LBS no low dome + IDX N4",
      key = "13s-lbs-no-low-dome-idx-n4",
      change = "4-node length-based selectivity with low dome constraints removed and index monotone",
      notes = "Removes the most restrictive terminal-zero constraints and stabilizes index tails.",
      edits = flags(global(61, 4), fish(dome_low, 16, 0), fish(dome_low, 3, 37), fish(idx, 16, 1))
    ),
    list(
      step_id = "13t-LBS-YoungZero-PSPLDOM-N4",
      substep = "13t",
      label = "LBS young-zero PS/PL/DOM N4",
      key = "13t-lbs-youngzero-pspldom-n4",
      change = "4-node length-based selectivity with age-1 zero selectivity for PS/PL/DOM gears",
      notes = "Tests whether small-fish fit is pulling selectivity and depletion upward.",
      edits = flags(global(61, 4), fish(ps_pl_dom, 75, 1))
    ),
    list(
      step_id = "13u-LBS-IDXyoungzero-N4",
      substep = "13u",
      label = "LBS IDX young-zero N4",
      key = "13u-lbs-idx-youngzero-n4",
      change = "4-node length-based selectivity with monotone index selectivity and young-index zero selectivity",
      notes = "Index fisheries get 16 = 1 and 75 = 2.",
      edits = flags(global(61, 4), fish(idx, 16, 1), fish(idx, 75, 2))
    ),
    list(
      step_id = "13v-LBS-HL75-3-N4",
      substep = "13v",
      label = "LBS HL75 3 N4",
      key = "13v-lbs-hl75-3-n4",
      change = "4-node length-based selectivity with HL young-zero age count relaxed",
      notes = "Changes HL fisheries 14-15 from 75 = 5 to 75 = 3.",
      edits = flags(global(61, 4), fish(c(14, 15), 75, 3))
    ),
    list(
      step_id = "13w-LBS-LL75-1-N4",
      substep = "13w",
      label = "LBS LL75 1 N4",
      key = "13w-lbs-ll75-1-n4",
      change = "4-node length-based selectivity with LL young-zero age count relaxed",
      notes = "Changes longline fisheries that had 75 = 2 to 75 = 1.",
      edits = flags(global(61, 4), fish(ll_young_zero, 75, 1))
    ),
    list(
      step_id = "13x-LBS-Bound359-1000-N4",
      substep = "13x",
      label = "LBS bound359 1000 N4",
      key = "13x-lbs-bound359-1000-n4",
      change = "4-node length-based selectivity with spline lower-bound penalty 359 = 1000",
      notes = "Adds a weak penalty against spline coefficients getting stuck below -15.",
      edits = flags(global(61, 4), parest(359, 1000))
    ),
    list(
      step_id = "13y-LBS-Bound359-10000-N4",
      substep = "13y",
      label = "LBS bound359 10000 N4",
      key = "13y-lbs-bound359-10000-n4",
      change = "4-node length-based selectivity with spline lower-bound penalty 359 = 10000",
      notes = "Adds a stronger penalty against spline coefficients getting stuck below -15.",
      edits = flags(global(61, 4), parest(359, 10000))
    )
  )
}

length_selectivity_sensitivity_rows <- function() {
  specs <- length_selectivity_sensitivity_specs()
  data.frame(
    step_id = vapply(specs, `[[`, character(1), "step_id"),
    enabled = rep(FALSE, length(specs)),
    major_step = rep("13-LengthBasedSel-Sensitivity", length(specs)),
    substep = vapply(specs, `[[`, character(1), "substep"),
    change_axis = vapply(specs, `[[`, character(1), "change"),
    model_label = vapply(specs, `[[`, character(1), "label"),
    job_title = paste(vapply(specs, `[[`, character(1), "substep"), vapply(specs, `[[`, character(1), "label")),
    job_key = vapply(specs, `[[`, character(1), "key"),
    run_mode = rep("doitall", length(specs)),
    region_count = rep(5L, length(specs)),
    kflow_memory = rep("8GB", length(specs)),
    mfcl_program_path = rep("", length(specs)),
    input_par = rep("", length(specs)),
    frq = rep("bet.frq", length(specs)),
    output_par = rep("", length(specs)),
    source_dir = rep("steps/13-LengthBasedSel/model", length(specs)),
    stringsAsFactors = FALSE
  )
}
