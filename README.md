# hivtools-analysis

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

Input packets come from the hivtools-data orderly archive on the Avenir Dropbox. Add it as a location once per clone:

```r
orderly::orderly_location_add_path(
  "hivtools-data",
  path = "~/Avenir Health Dropbox/Avenir DataSets/UNAIDS/hivtools-data/orderly"
)
```

Then pull the input packets for the current round before running:

```r
orderly::orderly_location_pull(
  'latest(name == "aaa_data_survey_breastfeeding" && parameter:version == "2026")',
  location = "hivtools-data",
  fetch_metadata = TRUE
)
```

Only the requested packet's files are pulled, not its upstream country packets.

## Running tasks

Every task takes `version`, which must currently be `"2026"` (the estimates round).

```r
orderly::orderly_run("bf_fit", parameters = list(version = "2026"))
orderly::orderly_run("bf_outputs", parameters = list(version = "2026"))
```

`bf_fit` runs 4 chains x 2000 iterations; expect several minutes.

## Credits

The breastfeeding model is ported from [InfantFeedingAnalysis](https://github.com/rlglaubius/InfantFeedingAnalysis) by Rob Glaubius (Avenir Health, MIT licence). See `docs/breastfeeding.md`.
