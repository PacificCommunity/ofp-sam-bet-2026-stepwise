# Job 16594 F15 length-frequency QC sensitivity

This campaign tests whether the strong biomass-profile signal from
`15.HL.PH.2` is robust to pre-specified data-QC treatments motivated by the
historical assessment treatment of the former Indonesia–Philippines large-fish
handline fishery.

The exact Job 16594 `S03-CommonTagTau-MIX015` inputs are frozen. The two F15
length-frequency variants are:

1. zero F15 length-bin counts below 68 cm;
2. zero F15 length-bin counts below 70 cm.

Each variant is run with Dirichlet-multinomial `Nmax=25` and `Nmax=15`, giving
four independent fits. Removed counts are not renormalised. No complete
quarterly composition and no complete fishery composition is removed. F15
catch and effort remain in every model. All non-F15 FRQ records and all other
Job 16594 model inputs and controls remain unchanged.

Reference comparisons are Job 16594 for unfiltered `Nmax=25` and Job 17222 for
unfiltered `Nmax=15` once that independently submitted fit has completed.
