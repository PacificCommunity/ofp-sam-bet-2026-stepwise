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
  ll_core <- c(1, 2, 4, 5, 7, 8, 9, 10)
  ll_recent <- 7:11
  ll_os <- c(5, 9)
  dome_all <- c(12, 13, 16:28)
  dome_low <- c(16, 17, 18, 21, 22, 23, 24)
  dome_dom_pl <- c(16, 21, 22, 23, 24)
  dome_ps <- c(12, 13, 17, 18, 19, 20, 25, 26, 27, 28)
  dome_ps_main <- c(19, 20, 25, 26, 27, 28)
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
    ),
    list(
      step_id = "13z-LBS-N7",
      substep = "13z",
      label = "LBS N7",
      key = "13z-lbs-n7",
      change = "length-based selectivity with 7 cubic-spline nodes",
      notes = "Adds flexibility beyond N6 without moving to an unconstrained high-node tail.",
      edits = flags(global(61, 7))
    ),
    list(
      step_id = "13aa-LBS-Bound359-1000-N5",
      substep = "13aa",
      label = "LBS bound359 1000 N5",
      key = "13aa-lbs-bound359-1000-n5",
      change = "5-node length-based selectivity with weak spline lower-bound penalty",
      notes = "Keeps the Step 13 node count and adds the weaker lower-bound stabilizer.",
      edits = flags(global(61, 5), parest(359, 1000))
    ),
    list(
      step_id = "13ab-LBS-Bound359-10000-N5",
      substep = "13ab",
      label = "LBS bound359 10000 N5",
      key = "13ab-lbs-bound359-10000-n5",
      change = "5-node length-based selectivity with stronger spline lower-bound penalty",
      notes = "Keeps baseline node count while testing whether low spline coefficients are destabilizing the fit.",
      edits = flags(global(61, 5), parest(359, 10000))
    ),
    list(
      step_id = "13ac-LBS-Bound359-1000-N6",
      substep = "13ac",
      label = "LBS bound359 1000 N6",
      key = "13ac-lbs-bound359-1000-n6",
      change = "6-node length-based selectivity with weak spline lower-bound penalty",
      notes = "Pairs the more flexible N6 spline with light lower-bound stabilization.",
      edits = flags(global(61, 6), parest(359, 1000))
    ),
    list(
      step_id = "13ad-LBS-Bound359-10000-N6",
      substep = "13ad",
      label = "LBS bound359 10000 N6",
      key = "13ad-lbs-bound359-10000-n6",
      change = "6-node length-based selectivity with stronger spline lower-bound penalty",
      notes = "Tests whether N6 needs stronger protection against very low spline coefficients.",
      edits = flags(global(61, 6), parest(359, 10000))
    ),
    list(
      step_id = "13ae-LBS-IDXmono-N6",
      substep = "13ae",
      label = "LBS IDXmono N6",
      key = "13ae-lbs-idxmono-n6",
      change = "6-node length-based selectivity with non-decreasing index selectivity",
      notes = "Checks whether index-tail stabilization still helps when the spline is more flexible.",
      edits = flags(global(61, 6), fish(idx, 16, 1))
    ),
    list(
      step_id = "13af-LBS-IDXmono-N7",
      substep = "13af",
      label = "LBS IDXmono N7",
      key = "13af-lbs-idxmono-n7",
      change = "7-node length-based selectivity with non-decreasing index selectivity",
      notes = "High-flexibility index-tail diagnostic without changing other gears.",
      edits = flags(global(61, 7), fish(idx, 16, 1))
    ),
    list(
      step_id = "13ag-LBS-IDXsoft-N5",
      substep = "13ag",
      label = "LBS IDX soft mono N5",
      key = "13ag-lbs-idxsoft-n5",
      change = "5-node index non-decreasing selectivity with softer penalty",
      notes = "Keeps Step 13 node count and applies fish flag 56 = 100000 to the index group.",
      edits = flags(global(61, 5), fish(idx, 16, 1), fish(idx, 56, 100000))
    ),
    list(
      step_id = "13ah-LBS-IDXvsoft-N5",
      substep = "13ah",
      label = "LBS IDX very soft mono N5",
      key = "13ah-lbs-idxvsoft-n5",
      change = "5-node index non-decreasing selectivity with very soft penalty",
      notes = "Uses fish flag 56 = 10000 for the index group to test penalty-strength sensitivity.",
      edits = flags(global(61, 5), fish(idx, 16, 1), fish(idx, 56, 10000))
    ),
    list(
      step_id = "13ai-LBS-IDX75-1-N4",
      substep = "13ai",
      label = "LBS IDX75 1 N4",
      key = "13ai-lbs-idx75-1-n4",
      change = "4-node index non-decreasing selectivity with one young age set to zero",
      notes = "Tests a light young-age exclusion for all index fisheries in their shared selectivity group.",
      edits = flags(global(61, 4), fish(idx, 16, 1), fish(idx, 75, 1))
    ),
    list(
      step_id = "13aj-LBS-IDX75-3-N4",
      substep = "13aj",
      label = "LBS IDX75 3 N4",
      key = "13aj-lbs-idx75-3-n4",
      change = "4-node index non-decreasing selectivity with three young ages set to zero",
      notes = "A stronger index young-age exclusion, applied consistently across the shared index group.",
      edits = flags(global(61, 4), fish(idx, 16, 1), fish(idx, 75, 3))
    ),
    list(
      step_id = "13ak-LBS-LLmono-N5",
      substep = "13ak",
      label = "LBS LLmono N5",
      key = "13ak-lbs-llmono-n5",
      change = "5-node length-based selectivity with non-decreasing longline selectivity",
      notes = "Keeps baseline node count while testing adult longline asymptotic tails.",
      edits = flags(global(61, 5), fish(ll, 16, 1))
    ),
    list(
      step_id = "13al-LBS-LLmono-N6",
      substep = "13al",
      label = "LBS LLmono N6",
      key = "13al-lbs-llmono-n6",
      change = "6-node length-based selectivity with non-decreasing longline selectivity",
      notes = "Tests whether LL monotone tails remain stable with more flexible length splines.",
      edits = flags(global(61, 6), fish(ll, 16, 1))
    ),
    list(
      step_id = "13am-LBS-LLcoreMono-N4",
      substep = "13am",
      label = "LBS LL core mono N4",
      key = "13am-lbs-llcoremono-n4",
      change = "4-node non-decreasing selectivity for core adult longline fisheries",
      notes = "Targets adult longline groups that already carry the inherited young-zero pattern.",
      edits = flags(global(61, 4), fish(ll_core, 16, 1))
    ),
    list(
      step_id = "13an-LBS-LLcoreMono-N5",
      substep = "13an",
      label = "LBS LL core mono N5",
      key = "13an-lbs-llcoremono-n5",
      change = "5-node non-decreasing selectivity for core adult longline fisheries",
      notes = "Same core LL diagnostic at the Step 13 node count.",
      edits = flags(global(61, 5), fish(ll_core, 16, 1))
    ),
    list(
      step_id = "13ao-LBS-LLrecentMono-N4",
      substep = "13ao",
      label = "LBS LL recent mono N4",
      key = "13ao-lbs-llrecentmono-n4",
      change = "4-node non-decreasing selectivity for later longline fishery groups",
      notes = "Focuses on the later/regional longline groups 7-11 rather than all longline gears.",
      edits = flags(global(61, 4), fish(ll_recent, 16, 1))
    ),
    list(
      step_id = "13ap-LBS-LLOSmono-N4",
      substep = "13ap",
      label = "LBS LL OS mono N4",
      key = "13ap-lbs-llosmono-n4",
      change = "4-node non-decreasing selectivity for oceanic longline groups",
      notes = "Targets the LL.OS-derived fisheries 5 and 9, including the already monotone old6-derived group.",
      edits = flags(global(61, 4), fish(ll_os, 16, 1))
    ),
    list(
      step_id = "13aq-LBS-LL75-0-N4",
      substep = "13aq",
      label = "LBS LL75 0 N4",
      key = "13aq-lbs-ll75-0-n4",
      change = "4-node length-based selectivity with inherited longline young-zero settings removed",
      notes = "Allows selected longline groups to estimate young-age selectivity rather than forcing the first two ages to zero.",
      edits = flags(global(61, 4), fish(ll_young_zero, 75, 0))
    ),
    list(
      step_id = "13ar-LBS-LL75-3-N4",
      substep = "13ar",
      label = "LBS LL75 3 N4",
      key = "13ar-lbs-ll75-3-n4",
      change = "4-node length-based selectivity with stronger longline young-zero settings",
      notes = "Tests whether excluding one additional young age stabilizes adult longline selectivity.",
      edits = flags(global(61, 4), fish(ll_young_zero, 75, 3))
    ),
    list(
      step_id = "13as-LBS-HL75-4-N4",
      substep = "13as",
      label = "LBS HL75 4 N4",
      key = "13as-lbs-hl75-4-n4",
      change = "4-node length-based selectivity with moderately relaxed HL young-zero age count",
      notes = "Intermediate HL setting between the inherited 75 = 5 and the 75 = 3 sensitivity.",
      edits = flags(global(61, 4), fish(c(14, 15), 75, 4))
    ),
    list(
      step_id = "13at-LBS-HL75-2-N4",
      substep = "13at",
      label = "LBS HL75 2 N4",
      key = "13at-lbs-hl75-2-n4",
      change = "4-node length-based selectivity with strongly relaxed HL young-zero age count",
      notes = "Tests whether the handline young-age exclusion is too restrictive.",
      edits = flags(global(61, 4), fish(c(14, 15), 75, 2))
    ),
    list(
      step_id = "13au-LBS-LLIDXmono-N6",
      substep = "13au",
      label = "LBS LL+IDXmono N6",
      key = "13au-lbs-llidxmono-n6",
      change = "6-node non-decreasing longline and index selectivity",
      notes = "Adult/index monotone-tail diagnostic with more flexible selectivity-at-length.",
      edits = flags(global(61, 6), fish(c(ll, idx), 16, 1))
    ),
    list(
      step_id = "13av-LBS-LLIDXmono-N7",
      substep = "13av",
      label = "LBS LL+IDXmono N7",
      key = "13av-lbs-llidxmono-n7",
      change = "7-node non-decreasing longline and index selectivity",
      notes = "Highest-node adult/index monotone diagnostic retained in this grid.",
      edits = flags(global(61, 7), fish(c(ll, idx), 16, 1))
    ),
    list(
      step_id = "13aw-LBS-LLIDXsoft-N5",
      substep = "13aw",
      label = "LBS LL+IDX soft mono N5",
      key = "13aw-lbs-llidxsoft-n5",
      change = "5-node non-decreasing longline/index selectivity with softer penalty",
      notes = "Baseline node count with fish flag 56 = 100000 on adult and index groups.",
      edits = flags(global(61, 5), fish(c(ll, idx), 16, 1), fish(c(ll, idx), 56, 100000))
    ),
    list(
      step_id = "13ax-LBS-LLIDXvsoft-N5",
      substep = "13ax",
      label = "LBS LL+IDX very soft mono N5",
      key = "13ax-lbs-llidxvsoft-n5",
      change = "5-node non-decreasing longline/index selectivity with very soft penalty",
      notes = "Baseline node count with fish flag 56 = 10000 on adult and index groups.",
      edits = flags(global(61, 5), fish(c(ll, idx), 16, 1), fish(c(ll, idx), 56, 10000))
    ),
    list(
      step_id = "13ay-LBS-LLIDXmidsoft-N4",
      substep = "13ay",
      label = "LBS LL+IDX mid-soft mono N4",
      key = "13ay-lbs-llidxmidsoft-n4",
      change = "4-node non-decreasing longline/index selectivity with intermediate penalty",
      notes = "Uses fish flag 56 = 500000, between the default and the soft case.",
      edits = flags(global(61, 4), fish(c(ll, idx), 16, 1), fish(c(ll, idx), 56, 500000))
    ),
    list(
      step_id = "13az-LBS-LLIDXmidvsoft-N4",
      substep = "13az",
      label = "LBS LL+IDX mid-very-soft mono N4",
      key = "13az-lbs-llidxmidvsoft-n4",
      change = "4-node non-decreasing longline/index selectivity with mid very-soft penalty",
      notes = "Uses fish flag 56 = 50000, between the soft and very soft cases.",
      edits = flags(global(61, 4), fish(c(ll, idx), 16, 1), fish(c(ll, idx), 56, 50000))
    ),
    list(
      step_id = "13ba-LBS-LLcoreIDXmono-N4",
      substep = "13ba",
      label = "LBS LL core + IDXmono N4",
      key = "13ba-lbs-llcoreidxmono-n4",
      change = "4-node non-decreasing core longline and index selectivity",
      notes = "Combines the index group with only core adult longline gears.",
      edits = flags(global(61, 4), fish(c(ll_core, idx), 16, 1))
    ),
    list(
      step_id = "13bb-LBS-LLOSIDXmono-N4",
      substep = "13bb",
      label = "LBS LL OS + IDXmono N4",
      key = "13bb-lbs-llosidxmono-n4",
      change = "4-node non-decreasing oceanic longline and index selectivity",
      notes = "Combines index monotonicity with the LL.OS-derived adult groups.",
      edits = flags(global(61, 4), fish(c(ll_os, idx), 16, 1))
    ),
    list(
      step_id = "13bc-LBS-PSdome20-N4",
      substep = "13bc",
      label = "LBS PS dome20 N4",
      key = "13bc-lbs-psdome20-n4",
      change = "4-node length-based selectivity with main purse-seine dome cutoffs set to 20",
      notes = "Applies a common lower cutoff to the main associated/unassociated PS groups while respecting shared selectivity groups.",
      edits = flags(global(61, 4), fish(dome_ps_main, 3, 20))
    ),
    list(
      step_id = "13bd-LBS-PSdome35-N4",
      substep = "13bd",
      label = "LBS PS dome35 N4",
      key = "13bd-lbs-psdome35-n4",
      change = "4-node length-based selectivity with main purse-seine dome cutoffs set to 35",
      notes = "A high-cutoff PS case that relaxes terminal-zero pressure without removing the dome form.",
      edits = flags(global(61, 4), fish(dome_ps_main, 3, 35))
    ),
    list(
      step_id = "13be-LBS-DOMPLdome15-N4",
      substep = "13be",
      label = "LBS DOM/PL dome15 N4",
      key = "13be-lbs-dompldome15-n4",
      change = "4-node length-based selectivity with DOM/PL cutoffs set to 15",
      notes = "Moderately relaxes the very low domestic and pole-line terminal-zero cutoffs.",
      edits = flags(global(61, 4), fish(dome_dom_pl, 3, 15))
    ),
    list(
      step_id = "13bf-LBS-DOMPLdome25-N4",
      substep = "13bf",
      label = "LBS DOM/PL dome25 N4",
      key = "13bf-lbs-dompldome25-n4",
      change = "4-node length-based selectivity with DOM/PL cutoffs set to 25",
      notes = "Strongly relaxes DOM/PL terminal-zero cutoffs while keeping the dome mechanism.",
      edits = flags(global(61, 4), fish(dome_dom_pl, 3, 25))
    ),
    list(
      step_id = "13bg-LBS-NoPSDome-N4",
      substep = "13bg",
      label = "LBS no PS dome N4",
      key = "13bg-lbs-no-ps-dome-n4",
      change = "4-node length-based selectivity with PS/JP dome constraints removed",
      notes = "Removes dome/terminal-zero constraints for PS/JP gears only, preserving DOM/PL constraints.",
      edits = flags(global(61, 4), fish(dome_ps, 16, 0), fish(dome_ps, 3, 37))
    ),
    list(
      step_id = "13bh-LBS-NoDOMPLDome-N4",
      substep = "13bh",
      label = "LBS no DOM/PL dome N4",
      key = "13bh-lbs-no-dompl-dome-n4",
      change = "4-node length-based selectivity with DOM/PL dome constraints removed",
      notes = "Removes dome/terminal-zero constraints for domestic and pole-line small-fish gears only.",
      edits = flags(global(61, 4), fish(dome_dom_pl, 16, 0), fish(dome_dom_pl, 3, 37))
    ),
    list(
      step_id = "13bi-LBS-Surface75-2-N4",
      substep = "13bi",
      label = "LBS surface75 2 N4",
      key = "13bi-lbs-surface75-2-n4",
      change = "4-node length-based selectivity with two young ages set to zero for surface/small-fish gears",
      notes = "A stronger young-age exclusion for PS/PL/DOM gears, applied consistently over shared selectivity groups.",
      edits = flags(global(61, 4), fish(ps_pl_dom, 75, 2))
    ),
    list(
      step_id = "13bj-LBS-LLIDXsoft-N6",
      substep = "13bj",
      label = "LBS LL+IDX soft mono N6",
      key = "13bj-lbs-llidxsoft-n6",
      change = "6-node non-decreasing longline/index selectivity with softer penalty",
      notes = "Crosses the flexible N6 spline with the adult/index monotone penalty-strength axis.",
      edits = flags(global(61, 6), fish(c(ll, idx), 16, 1), fish(c(ll, idx), 56, 100000))
    ),
    list(
      step_id = "13bk-LBS-LLIDXvsoft-N6",
      substep = "13bk",
      label = "LBS LL+IDX very soft mono N6",
      key = "13bk-lbs-llidxvsoft-n6",
      change = "6-node non-decreasing longline/index selectivity with very soft penalty",
      notes = "Tests whether a more flexible spline needs only light monotone-tail guidance.",
      edits = flags(global(61, 6), fish(c(ll, idx), 16, 1), fish(c(ll, idx), 56, 10000))
    ),
    list(
      step_id = "13bl-LBS-LLIDXsoft-N3",
      substep = "13bl",
      label = "LBS LL+IDX soft mono N3",
      key = "13bl-lbs-llidxsoft-n3",
      change = "3-node non-decreasing longline/index selectivity with softer penalty",
      notes = "Crosses the strongest smoothing case with a less rigid monotone-tail penalty.",
      edits = flags(global(61, 3), fish(c(ll, idx), 16, 1), fish(c(ll, idx), 56, 100000))
    ),
    list(
      step_id = "13bm-LBS-LLIDXvsoft-N3",
      substep = "13bm",
      label = "LBS LL+IDX very soft mono N3",
      key = "13bm-lbs-llidxvsoft-n3",
      change = "3-node non-decreasing longline/index selectivity with very soft penalty",
      notes = "Separates low node count from a hard monotone-tail constraint.",
      edits = flags(global(61, 3), fish(c(ll, idx), 16, 1), fish(c(ll, idx), 56, 10000))
    ),
    list(
      step_id = "13bn-LBS-IDXsoft-N4",
      substep = "13bn",
      label = "LBS IDX soft mono N4",
      key = "13bn-lbs-idxsoft-n4",
      change = "4-node index non-decreasing selectivity with softer penalty",
      notes = "Adds the missing N4 member of the index-only penalty-strength axis.",
      edits = flags(global(61, 4), fish(idx, 16, 1), fish(idx, 56, 100000))
    ),
    list(
      step_id = "13bo-LBS-IDXvsoft-N4",
      substep = "13bo",
      label = "LBS IDX very soft mono N4",
      key = "13bo-lbs-idxvsoft-n4",
      change = "4-node index non-decreasing selectivity with very soft penalty",
      notes = "Tests whether the index tail needs a hard monotone penalty at the N4 node count.",
      edits = flags(global(61, 4), fish(idx, 16, 1), fish(idx, 56, 10000))
    ),
    list(
      step_id = "13bp-LBS-IDXsoft-N6",
      substep = "13bp",
      label = "LBS IDX soft mono N6",
      key = "13bp-lbs-idxsoft-n6",
      change = "6-node index non-decreasing selectivity with softer penalty",
      notes = "Crosses flexible length selectivity with a softer index monotone-tail penalty.",
      edits = flags(global(61, 6), fish(idx, 16, 1), fish(idx, 56, 100000))
    ),
    list(
      step_id = "13bq-LBS-IDXvsoft-N6",
      substep = "13bq",
      label = "LBS IDX very soft mono N6",
      key = "13bq-lbs-idxvsoft-n6",
      change = "6-node index non-decreasing selectivity with very soft penalty",
      notes = "Flexible index-tail case with only light monotone guidance.",
      edits = flags(global(61, 6), fish(idx, 16, 1), fish(idx, 56, 10000))
    ),
    list(
      step_id = "13br-LBS-LLmono-N3",
      substep = "13br",
      label = "LBS LLmono N3",
      key = "13br-lbs-llmono-n3",
      change = "3-node length-based selectivity with non-decreasing longline selectivity",
      notes = "Adds the low-node member of the longline-only monotone-tail axis.",
      edits = flags(global(61, 3), fish(ll, 16, 1))
    ),
    list(
      step_id = "13bs-LBS-LLmono-N7",
      substep = "13bs",
      label = "LBS LLmono N7",
      key = "13bs-lbs-llmono-n7",
      change = "7-node length-based selectivity with non-decreasing longline selectivity",
      notes = "High-flexibility longline-only monotone-tail diagnostic.",
      edits = flags(global(61, 7), fish(ll, 16, 1))
    ),
    list(
      step_id = "13bt-LBS-Bound359-1000-LLIDX-N4",
      substep = "13bt",
      label = "LBS bound359 1000 LL+IDX N4",
      key = "13bt-lbs-bound359-1000-llidx-n4",
      change = "4-node adult/index monotone selectivity with weak spline lower-bound penalty",
      notes = "Crosses the lower-bound stabilizer with the main adult/index tail diagnostic.",
      edits = flags(global(61, 4), parest(359, 1000), fish(c(ll, idx), 16, 1))
    ),
    list(
      step_id = "13bu-LBS-Bound359-10000-LLIDX-N4",
      substep = "13bu",
      label = "LBS bound359 10000 LL+IDX N4",
      key = "13bu-lbs-bound359-10000-llidx-n4",
      change = "4-node adult/index monotone selectivity with stronger spline lower-bound penalty",
      notes = "Tests whether lower-tail spline stabilization and monotone adult/index tails act together.",
      edits = flags(global(61, 4), parest(359, 10000), fish(c(ll, idx), 16, 1))
    ),
    list(
      step_id = "13bv-LBS-Bound359-1000-LLIDX-N5",
      substep = "13bv",
      label = "LBS bound359 1000 LL+IDX N5",
      key = "13bv-lbs-bound359-1000-llidx-n5",
      change = "5-node adult/index monotone selectivity with weak spline lower-bound penalty",
      notes = "Baseline node count crossed with both adult/index monotone tails and weak lower-bound stabilization.",
      edits = flags(global(61, 5), parest(359, 1000), fish(c(ll, idx), 16, 1))
    ),
    list(
      step_id = "13bw-LBS-Bound359-10000-LLIDX-N5",
      substep = "13bw",
      label = "LBS bound359 10000 LL+IDX N5",
      key = "13bw-lbs-bound359-10000-llidx-n5",
      change = "5-node adult/index monotone selectivity with stronger spline lower-bound penalty",
      notes = "Baseline node count with the stronger lower-bound stabilizer and adult/index monotone tails.",
      edits = flags(global(61, 5), parest(359, 10000), fish(c(ll, idx), 16, 1))
    ),
    list(
      step_id = "13bx-LBS-Bound359-1000-IDX-N4",
      substep = "13bx",
      label = "LBS bound359 1000 IDX N4",
      key = "13bx-lbs-bound359-1000-idx-n4",
      change = "4-node index monotone selectivity with weak spline lower-bound penalty",
      notes = "Separates index-tail stabilization from adult longline monotonicity under the lower-bound penalty.",
      edits = flags(global(61, 4), parest(359, 1000), fish(idx, 16, 1))
    ),
    list(
      step_id = "13by-LBS-Bound359-10000-IDX-N4",
      substep = "13by",
      label = "LBS bound359 10000 IDX N4",
      key = "13by-lbs-bound359-10000-idx-n4",
      change = "4-node index monotone selectivity with stronger spline lower-bound penalty",
      notes = "Index-only tail case crossed with the stronger spline lower-bound stabilizer.",
      edits = flags(global(61, 4), parest(359, 10000), fish(idx, 16, 1))
    ),
    list(
      step_id = "13bz-LBS-NoPSDome-IDX-N4",
      substep = "13bz",
      label = "LBS no PS dome + IDX N4",
      key = "13bz-lbs-no-ps-dome-idx-n4",
      change = "4-node selectivity with PS/JP dome constraints removed and index monotone",
      notes = "Checks whether surface-fishery dome assumptions and index tails jointly explain the depletion shift.",
      edits = flags(global(61, 4), fish(dome_ps, 16, 0), fish(dome_ps, 3, 37), fish(idx, 16, 1))
    ),
    list(
      step_id = "13ca-LBS-NoDOMPLDome-IDX-N4",
      substep = "13ca",
      label = "LBS no DOM/PL dome + IDX N4",
      key = "13ca-lbs-no-dompl-dome-idx-n4",
      change = "4-node selectivity with DOM/PL dome constraints removed and index monotone",
      notes = "Targets domestic and pole-line dome assumptions while stabilizing the index tail.",
      edits = flags(global(61, 4), fish(dome_dom_pl, 16, 0), fish(dome_dom_pl, 3, 37), fish(idx, 16, 1))
    ),
    list(
      step_id = "13cb-LBS-PSdome20-IDX-N4",
      substep = "13cb",
      label = "LBS PS dome20 + IDX N4",
      key = "13cb-lbs-psdome20-idx-n4",
      change = "4-node selectivity with main PS dome cutoffs set to 20 and index monotone",
      notes = "Lower PS terminal-zero cutoff crossed with the index-tail diagnostic.",
      edits = flags(global(61, 4), fish(dome_ps_main, 3, 20), fish(idx, 16, 1))
    ),
    list(
      step_id = "13cc-LBS-PSdome35-IDX-N4",
      substep = "13cc",
      label = "LBS PS dome35 + IDX N4",
      key = "13cc-lbs-psdome35-idx-n4",
      change = "4-node selectivity with main PS dome cutoffs set to 35 and index monotone",
      notes = "Higher PS terminal-zero cutoff crossed with index-tail stabilization.",
      edits = flags(global(61, 4), fish(dome_ps_main, 3, 35), fish(idx, 16, 1))
    ),
    list(
      step_id = "13cd-LBS-DOMPLdome15-IDX-N4",
      substep = "13cd",
      label = "LBS DOM/PL dome15 + IDX N4",
      key = "13cd-lbs-dompldome15-idx-n4",
      change = "4-node selectivity with DOM/PL cutoffs set to 15 and index monotone",
      notes = "Moderate DOM/PL cutoff relaxation crossed with index-tail stabilization.",
      edits = flags(global(61, 4), fish(dome_dom_pl, 3, 15), fish(idx, 16, 1))
    ),
    list(
      step_id = "13ce-LBS-DOMPLdome25-IDX-N4",
      substep = "13ce",
      label = "LBS DOM/PL dome25 + IDX N4",
      key = "13ce-lbs-dompldome25-idx-n4",
      change = "4-node selectivity with DOM/PL cutoffs set to 25 and index monotone",
      notes = "Strong DOM/PL cutoff relaxation crossed with index-tail stabilization.",
      edits = flags(global(61, 4), fish(dome_dom_pl, 3, 25), fish(idx, 16, 1))
    ),
    list(
      step_id = "13cf-LBS-NoDome-LLIDX-N4",
      substep = "13cf",
      label = "LBS no dome + LL+IDX N4",
      key = "13cf-lbs-nodome-llidx-n4",
      change = "4-node selectivity with all inherited dome constraints removed and adult/index monotone",
      notes = "Strong interaction case for dome assumptions plus adult/index tail behavior.",
      edits = flags(global(61, 4), fish(dome_all, 16, 0), fish(dome_all, 3, 37), fish(c(ll, idx), 16, 1))
    ),
    list(
      step_id = "13cg-LBS-RelaxLowDome-LLIDX-N4",
      substep = "13cg",
      label = "LBS relax low dome + LL+IDX N4",
      key = "13cg-lbs-relax-low-dome-llidx-n4",
      change = "4-node selectivity with low terminal-zero cutoffs relaxed and adult/index monotone",
      notes = "Less extreme dome/tail interaction than removing all dome constraints.",
      edits = flags(global(61, 4), fish(dome_low, 3, 20), fish(c(ll, idx), 16, 1))
    ),
    list(
      step_id = "13ch-LBS-Surface75-2-IDX-N4",
      substep = "13ch",
      label = "LBS surface75 2 + IDX N4",
      key = "13ch-lbs-surface75-2-idx-n4",
      change = "4-node selectivity with surface young-zero 2 and index monotone",
      notes = "Crosses small-fish young-zero settings with index-tail stabilization.",
      edits = flags(global(61, 4), fish(ps_pl_dom, 75, 2), fish(idx, 16, 1))
    ),
    list(
      step_id = "13ci-LBS-Surface75-2-LLIDX-N4",
      substep = "13ci",
      label = "LBS surface75 2 + LL+IDX N4",
      key = "13ci-lbs-surface75-2-llidx-n4",
      change = "4-node selectivity with surface young-zero 2 and adult/index monotone",
      notes = "Full young-zero plus adult/index tail interaction case.",
      edits = flags(global(61, 4), fish(ps_pl_dom, 75, 2), fish(c(ll, idx), 16, 1))
    ),
    list(
      step_id = "13cj-LBS-LL75-0-LLIDX-N4",
      substep = "13cj",
      label = "LBS LL75 0 + LL+IDX N4",
      key = "13cj-lbs-ll75-0-llidx-n4",
      change = "4-node selectivity with longline young-zero removed and adult/index monotone",
      notes = "Tests whether LL young-age zeros and adult/index monotone tails are compensating for each other.",
      edits = flags(global(61, 4), fish(ll_young_zero, 75, 0), fish(c(ll, idx), 16, 1))
    ),
    list(
      step_id = "13ck-LBS-LL75-1-LLIDX-N4",
      substep = "13ck",
      label = "LBS LL75 1 + LL+IDX N4",
      key = "13ck-lbs-ll75-1-llidx-n4",
      change = "4-node selectivity with LL young-zero age count relaxed and adult/index monotone",
      notes = "Middle interaction case between removing and strengthening LL young-age zeros.",
      edits = flags(global(61, 4), fish(ll_young_zero, 75, 1), fish(c(ll, idx), 16, 1))
    ),
    list(
      step_id = "13cl-LBS-LL75-3-LLIDX-N4",
      substep = "13cl",
      label = "LBS LL75 3 + LL+IDX N4",
      key = "13cl-lbs-ll75-3-llidx-n4",
      change = "4-node selectivity with stronger LL young-zero settings and adult/index monotone",
      notes = "Strengthens young-age exclusion while keeping adult/index tails monotone.",
      edits = flags(global(61, 4), fish(ll_young_zero, 75, 3), fish(c(ll, idx), 16, 1))
    ),
    list(
      step_id = "13cm-LBS-HL75-2-LLIDX-N4",
      substep = "13cm",
      label = "LBS HL75 2 + LL+IDX N4",
      key = "13cm-lbs-hl75-2-llidx-n4",
      change = "4-node selectivity with strongly relaxed HL young-zero count and adult/index monotone",
      notes = "Tests whether handline young-zero assumptions interact with the adult/index tail signal.",
      edits = flags(global(61, 4), fish(c(14, 15), 75, 2), fish(c(ll, idx), 16, 1))
    ),
    list(
      step_id = "13cn-LBS-HL75-4-LLIDX-N4",
      substep = "13cn",
      label = "LBS HL75 4 + LL+IDX N4",
      key = "13cn-lbs-hl75-4-llidx-n4",
      change = "4-node selectivity with moderately relaxed HL young-zero count and adult/index monotone",
      notes = "Intermediate handline young-zero interaction case.",
      edits = flags(global(61, 4), fish(c(14, 15), 75, 4), fish(c(ll, idx), 16, 1))
    ),
    list(
      step_id = "13co-LBS-IDX75-1-LLIDX-N4",
      substep = "13co",
      label = "LBS IDX75 1 + LL+IDX N4",
      key = "13co-lbs-idx75-1-llidx-n4",
      change = "4-node adult/index monotone selectivity with one young index age set to zero",
      notes = "Light index young-age exclusion crossed with LL+index adult-tail monotonicity.",
      edits = flags(global(61, 4), fish(c(ll, idx), 16, 1), fish(idx, 75, 1))
    ),
    list(
      step_id = "13cp-LBS-IDX75-2-LLIDX-N4",
      substep = "13cp",
      label = "LBS IDX75 2 + LL+IDX N4",
      key = "13cp-lbs-idx75-2-llidx-n4",
      change = "4-node adult/index monotone selectivity with two young index ages set to zero",
      notes = "Middle index young-age exclusion crossed with LL+index adult-tail monotonicity.",
      edits = flags(global(61, 4), fish(c(ll, idx), 16, 1), fish(idx, 75, 2))
    ),
    list(
      step_id = "13cq-LBS-IDX75-3-LLIDX-N4",
      substep = "13cq",
      label = "LBS IDX75 3 + LL+IDX N4",
      key = "13cq-lbs-idx75-3-llidx-n4",
      change = "4-node adult/index monotone selectivity with three young index ages set to zero",
      notes = "Strong index young-age exclusion crossed with LL+index adult-tail monotonicity.",
      edits = flags(global(61, 4), fish(c(ll, idx), 16, 1), fish(idx, 75, 3))
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
