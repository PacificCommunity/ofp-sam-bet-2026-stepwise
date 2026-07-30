# Job 18518 DM-fix provenance

These files were copied from the completed Job 18518 output archive, SHA256
`4bc58a7dbe4cc4c91b3d7822413d2393f353ee55a474b2bbd228931bd2c5622a`.

Job 18518 continued the checksum-verified Job 18400 PAR and changed only fish
flag 69 from one to zero. This fixed the eight G8-grouped `fish_pars(22)`
concentration intercepts at their fitted values, all numerically equal to the
upper bound of 7. Fish flag 89 remained one, leaving eight grouped
`fish_pars(23)` relative-sample-size exponents estimated. The DM-noRE setting
and `Nmax=25` remained active.

The final-exploration scripts reproduce that treatment from a fresh
`bet.ini`: they explicitly write 7 to all fishery copies of row 22 before
applying the G8 map and `flag 69=0`.
