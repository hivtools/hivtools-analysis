# hivtools.analysis 0.1.0

* Set up hivtools-analysis as an orderly2 repo for downstream survey analyses. Survey extraction stays in hivtools-data; tasks here pull its published packets from the shared Dropbox archive.
* Add breastfeeding duration model by maternal HIV status, ported from InfantFeedingAnalysis (Rob Glaubius, `7a18b95`). `bf_fit` runs the joint Stan fit on `aaa_data_survey_breastfeeding`; `bf_outputs` writes `bf-post-hiv.csv`, `bf-pars-ceff.csv`, `bf-pars-reff.csv` and a fit-check PDF. Validated against the original code: input data identical for all 65 surveys, and the fit samples the same posterior (medians within 0.5 pp). (#1)
* Update `bf-model.stan` array declarations to `array[]` syntax, which current Stan requires. The model is otherwise unchanged.
* Add `seed` parameter to `bf_fit` (default `20210518`). Previously fits were unseeded, so re-running gave different point estimates; now outputs are reproducible.
* Add `vignettes/run_breastfeeding_analysis.Rmd`, a step-by-step guide to setting up, pulling the input packet and running the analysis.
* Add DESCRIPTION (version and dependencies) and MIT licence.
