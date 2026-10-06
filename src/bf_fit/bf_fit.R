orderly::orderly_strict_mode()

params <- orderly::orderly_parameters(version = "2026", seed = 20210518L)

orderly::orderly_description(
  display = "Breastfeeding model fit",
  long = "Joint Stan fit of breastfeeding duration by maternal HIV status across
  all national DHS/AIS surveys. Ported from InfantFeedingAnalysis
  (R. Glaubius, MIT): log-logistic survival with country effects and
  regional time/HIV effects, point estimates taken as the max-lp__ draw."
)

orderly::orderly_dependency(
  "aaa_data_survey_breastfeeding",
  "latest(parameter:version == this:version)",
  c("depends/survey_breastfeeding.csv" = "survey_breastfeeding.csv")
)

orderly::orderly_resource("bf-model.stan")

orderly::orderly_artefact(
  description = "stanfit object and the survey data in the order the model indexes it",
  files = c("bf_fit.rds", "bf_data.csv")
)

library(dplyr)
library(readr)
library(rstan)

## Upstream used the PHIA bin midpoints [0,2] (2,4] ... (34,36]; data are
## binned with right = TRUE to match.
months <- c(1.5, seq(4, 36, 2))

dat <- read_csv("depends/survey_breastfeeding.csv", show_col_types = FALSE) |>
  arrange(country_name, survey_id, hiv, age)

## Survey j indexes the model; ordering matches upstream's `abstract`
## (CountryName, SurveyId), and country/region use alphabetical factor levels.
surveys <- dat |>
  distinct(survey_id, iso3, country_name, subregion_name, survey_year,
           survey_year_label, survey_type) |>
  arrange(country_name, survey_id) |>
  mutate(j = row_number(),
         country = as.integer(factor(country_name)),
         region = as.integer(factor(subregion_name)))

stopifnot(!anyDuplicated(surveys$survey_id),
          all(dat$age %in% seq_along(months)),
          all(dat$hiv %in% c("negative", "positive")))

dat <- dat |>
  left_join(select(surveys, survey_id, j), by = "survey_id") |>
  mutate(h = match(hiv, c("negative", "positive")))

## Fill X/Y by explicit index rather than upstream's array(data.flat$not.bf, ...),
## which relies on every survey having all 18 x 2 rows. Upstream keeps empty
## cells as 0-count rows; hivtools-data's extraction drops them, so they're
## filled with 0 here. Verified identical to upstream's X/Y for 2026 data.
n_surveys <- nrow(surveys)
X <- Y <- array(0, dim = c(length(months), n_surveys, 2))
idx <- cbind(dat$age, dat$j, dat$h)
X[idx] <- coalesce(dat$not_bf, 0)
Y[idx] <- coalesce(dat$yes_bf, 0)

n_country <- max(surveys$country)
n_region <- max(surveys$region)

stan_data <- list(
  n_surveys = n_surveys,
  n_countries = n_country,
  n_regions = n_region,
  n_months = length(months),
  month = months,
  country = as.array(surveys$country),
  region = as.array(surveys$region),
  survey_year = as.array(as.numeric(surveys$survey_year)),
  ref_year = 2010,
  X = X,
  Y = Y
)

param_init <- function(chain_id = 1) {
  list(
    base_bgn_hiv = as.array(rep(0, n_region)),
    base_med_hiv = as.array(rep(0, n_region)),
    base_bgn_arv = as.array(rep(0, n_region)),
    base_med_arv = as.array(rep(0, n_region)),
    base_slope_bgn = as.array(rep(0, n_region)),
    base_slope_med = as.array(rep(0, n_region)),
    base_slope_shp = as.array(rep(0, n_region)),
    ceff_bgn = as.array(rep(0.8, n_country)),
    ceff_med = as.array(rep(log(22), n_country)),
    ceff_shp = as.array(rep(log(4), n_country))
  )
}

options(mc.cores = min(4, parallel::detectCores()))

fit <- stan(file = "bf-model.stan", data = stan_data, init = param_init,
            iter = 2000, chains = 4, seed = params$seed)

saveRDS(fit, "bf_fit.rds")
write_csv(select(dat, -h) |> left_join(select(surveys, survey_id, country, region), by = "survey_id"),
          "bf_data.csv", na = "")
