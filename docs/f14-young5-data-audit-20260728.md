# F14 youngest-age selectivity sensitivity audit

This sensitivity adds fish flag 75=5 to F14 (HL.ID.2) and retains the
existing flag for F15 (HL.PH.2). The two fisheries are independent
selectivity groups (12 and 13, respectively).

The frozen S03 length-frequency data show that F14 is the only fishery
without a positive youngest-age constraint that is comparably
adult-dominated:

| Fishery | Length count | Minimum (cm) | 5th percentile (cm) | Median (cm) | Below 70 cm | Below 80 cm | Current flag 75 |
|---|---:|---:|---:|---:|---:|---:|---:|
| F14 HL.ID.2 | 3,122 | 72 | 98 | 128 | 0.00% | 0.16% | 0 |
| F15 HL.PH.2, raw | 41,908 | 14 | 78 | 130 | 2.52% | 5.64% | 5 |
| F15 HL.PH.2, after `<70 cm` QC | 40,851 | 70 | 84 | 132 | 0.00% | — | 5 |

For the other fisheries without a positive flag 75 (F16–F28), the
observed count below 70 cm ranges from 54.79% to 99.60%. Adding the same
youngest-five-age constraint to those fisheries would suppress observed
juvenile information, so they are not included in this sensitivity.

Both model rows are independent `doitall` fits from `bet.ini` and frozen
S03 inputs. They differ only in the regional recruitment-distribution
penalty (0.1 versus 0.2). Both retain Nmax=25, F15 `<70 cm` QC, MGC
1e-4, fixed natural mortality, common estimated tag tau, and SC22-IP10
K=0.15 mixing.
