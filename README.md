# hivtools-analysis

**Version 0.1.0** · see [NEWS.md](NEWS.md) for changes in each version.

An [orderly2](https://mrc-ide.github.io/orderly/) pipeline for the downstream survey analyses that produce Spectrum and SHIPP inputs. Survey extraction happens in [hivtools-data](https://github.com/hivtools/hivtools-data); this repo fits models to the pooled survey outputs it publishes.

| Analysis | Tasks | Input from hivtools-data | Output |
|---|---|---|---|
| Breastfeeding duration by maternal HIV status | `bf_fit` → `bf_outputs` | `aaa_data_survey_breastfeeding` | Spectrum AIM PMTCT breastfeeding inputs |
| SHIPP sexual-behaviour small-area model | planned, see hivtools-data `docs/shipp-sae-migration.md` | `aaa_data_survey_sexbehav`, `aaa_data_areas` | SHIPP tool inputs |

## Repository structure

```
src/     orderly tasks
docs/    per-analysis notes: provenance, design decisions, validation
```

Generated directories (gitignored): `.outpack/`, `archive/`, `draft/`.

## Setup

```r
install.packages(c("orderly", "rstan", "dplyr", "readr", "ggplot2", "countrycode"))
```

`rstan` must be >= 2.32 (the Stan model uses `array[]` syntax).

### Inputs from hivtools-data

Input packets come from the hivtools-data orderly archive on the Avenir Dropbox (`Avenir DataSets/UNAIDS/hivtools-data/orderly`), which must be **available offline**.

Set up once per clone:

1. Run `orderly::orderly_init()`, because `.outpack/` is gitignored.
2. Set `HIVTOOLS_DATA_ORDERLY` in `~/.Renviron`. This is the same variable hivtools-data uses.
3. Register the location: `orderly::orderly_location_add_path("hivtools-data", Sys.getenv("HIVTOOLS_DATA_ORDERLY"))`.

## Running an analysis

Each analysis has a step-by-step guide in `vignettes/`:

| Analysis | Guide |
|---|---|
| Breastfeeding duration | [`vignettes/run_breastfeeding_analysis.Rmd`](vignettes/run_breastfeeding_analysis.Rmd) |

Every task takes `version`, which must currently be `"2026"` (the estimates round).

## Credits

The breastfeeding model is ported from [InfantFeedingAnalysis](https://github.com/rlglaubius/InfantFeedingAnalysis) by Rob Glaubius (Avenir Health, MIT licence). See `docs/breastfeeding.md`.
