# Breastfeeding duration model

Estimates breastfeeding duration by maternal HIV status for the Spectrum AIM PMTCT module, from national DHS/AIS surveys in sub-Saharan Africa.

## Provenance

Ported from [rlglaubius/InfantFeedingAnalysis](https://github.com/rlglaubius/InfantFeedingAnalysis) at commit `7a18b95` (Rob Glaubius, Avenir Health, MIT licence).

| Upstream | Here |
|---|---|
| `bf-support.R::load.rdhs()`, `aggr.bf.data()` (DHS pull and survey-weighted aggregation) | hivtools-data: `shared/bf_helpers.R`, run inside each `{iso3}_data_survey*` task, pooled by `aaa_data_survey_breastfeeding` |
| `bf-model.R::bf.fit()`, `bf-model.stan` | `src/bf_fit` |
| `bf.matrix.hiv()`, `param.tables()`, `plot.model.fit()` | `src/bf_outputs` |
| `gen-figure.R` (regional trend figure) | not ported yet |
| `dhs-iso3166-map.xlsx` | not needed: hivtools-data carries ISO3 per survey; ISO numeric codes come from `countrycode` |

## Model

For survey *j* and HIV status *h*, the proportion of mothers still breastfeeding *t* months after their last birth is log-logistic:

```
propbf = u * (1 - 1 / (1 + (t / m)^-s))
```

- `u`: proportion who ever breastfed
- `m`: median duration among those who did
- `s`: shape

Each parameter combines:
- a country effect;
- a regional time trend relative to 2010.

For HIV+ mothers, `u` and `m` also get a regional HIV effect and an HIV × time interaction.

Regions are the DHS `SubregionName` values (Eastern, Western, Middle and Southern Africa). The model has no subnational component: each survey enters as one national table of 18 two-month bins by 2 HIV statuses. The likelihood is binomial on survey-weighted counts. There are no priors.

Point estimates are the max-`lp__` draw, as upstream.

## Changes from upstream

- **`bf-model.stan` syntax.** Old `real x[n]` array declarations are rewritten as `array[n] real x`, which current rstan's stanc requires. The model is otherwise identical.
- **Data array construction.** Upstream builds `X = array(data.flat$not.bf, dim = c(n_months, n_survey, 2))`, which relies on every survey having all 36 age × HIV rows. Upstream keeps empty cells as 0-count rows with `NA` estimates. hivtools-data's extraction drops them instead: for example, 137 HIV+ cells across the first 57 surveys checked. So `bf_fit` fills by explicit index, with missing cells set to 0. For the 2026 data this gives the same `X`/`Y` as upstream (largest difference 6e-14).
- **Seed.** `bf_fit` takes a `seed` parameter; upstream ran unseeded.
- **Plots.** Plots are one multi-page PDF via ggplot instead of per-survey TIFFs.

## Validation (2026-10-06)

- **Data.** `aaa_data_survey_breastfeeding` was compared with upstream `load.rdhs()`, run unmodified on the same day. All 65 surveys match:
    - weighted counts within 6e-14;
    - proportions and CIs within 1e-16;
    - unweighted N and survey metadata identical.
- **Fit.** `bf_fit` was compared with upstream `bf-model.R` on the same 62 surveys (before ZWE was fixed), with the same seed:
    - posterior means agree within Monte Carlo error (max diff 0.0066, ≤ 3.3 MC SEs);
    - posterior medians of HIV+ % not breastfeeding agree within 0.5 pp;
    - Rhat ≤ 1.003 for both.
- **Point estimate (open).** The max-`lp__` draw used for all outputs sits 10–14 pp from its own posterior median. It differs by up to 16.8 pp between the two fits, while the median 95% interval width is 7 pp. The proposal to Rob is to switch to `rstan::optimizing()`.

## Not yet ported or open

- Point estimate: see above.
- PHIA data: upstream never ingested it (there is a dead `pmtct` / `PMTCT_coverage` field), so there is nothing to port.
- `gen-figure.R`: the regional trend figure.
