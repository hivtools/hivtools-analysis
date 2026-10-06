orderly::orderly_strict_mode()

params <- orderly::orderly_parameters(version = "2026")

orderly::orderly_description(
  display = "Breastfeeding model outputs",
  long = "Spectrum inputs and diagnostics from the bf_fit breastfeeding model:
  HIV+ not-breastfeeding by survey (bf-post-hiv.csv), country and regional
  parameter tables for the AMModData InfantFeedingModel tab, fit plots."
)

orderly::orderly_dependency(
  "bf_fit",
  "latest(parameter:version == this:version)",
  c("depends/bf_fit.rds" = "bf_fit.rds", "depends/bf_data.csv" = "bf_data.csv")
)

orderly::orderly_artefact(
  description = "Spectrum PMTCT input: % not breastfeeding among HIV+ mothers, by survey",
  files = "bf-post-hiv.csv"
)
orderly::orderly_artefact(
  description = "Country and regional parameter estimates (AMModData InfantFeedingModel)",
  files = c("bf-pars-ceff.csv", "bf-pars-reff.csv")
)
orderly::orderly_artefact(
  description = "Model fit against survey data, one page per survey",
  files = "bf-fit-surveys.pdf"
)

library(dplyr)
library(ggplot2)
library(readr)

months <- c(1.5, seq(4, 36, 2))

fit <- readRDS("depends/bf_fit.rds")
dat <- read_csv("depends/bf_data.csv", show_col_types = FALSE)

surveys <- dat |>
  distinct(j, survey_id, iso3, country_name, subregion_name, country, region,
           survey_year_label, survey_type) |>
  arrange(j)

## One extract() call so every parameter shares the same draw permutation.
## Point estimates are the max-lp__ draw, as upstream ("post" there is a
## misnomer for this MLE-style estimate).
draws <- rstan::extract(fit, pars = c("lp__", "propbf", "ceff_bgn", "ceff_med",
                                      "ceff_shp", "base_slope_bgn",
                                      "base_bgn_hiv", "base_bgn_arv",
                                      "base_slope_med", "base_med_hiv",
                                      "base_med_arv", "base_slope_shp"))
best <- which.max(draws$lp__)

#' ## Spectrum input: % not breastfeeding, HIV+ mothers
#' Rows use Spectrum's [0,2) ... [34,36) labels, as upstream.

bf_hiv <- 100 * (1 - draws$propbf[best, , , 2])
bf_hiv <- matrix(bf_hiv, nrow = length(months),
                 dimnames = list(levels(cut(seq(1, 35, 2), seq(0, 36, 2),
                                            include.lowest = TRUE, right = FALSE)),
                                 surveys$survey_id))
write.csv(bf_hiv, "bf-post-hiv.csv")

#' ## Parameter tables

countries <- distinct(surveys, country, country_name, iso3, subregion_name) |>
  arrange(country)
stopifnot(!anyDuplicated(countries$country))

ceff <- data.frame(
  country = countries$country_name,
  isocode = countrycode::countrycode(countries$iso3, "iso3c", "iso3n"),
  region = countries$subregion_name,
  bgn = draws$ceff_bgn[best, ],
  med = draws$ceff_med[best, ],
  shp = draws$ceff_shp[best, ]
)
write.csv(ceff, "bf-pars-ceff.csv", row.names = FALSE)

regions <- distinct(surveys, region, subregion_name) |> arrange(region)
reff <- data.frame(
  region = regions$subregion_name,
  bgn.time = draws$base_slope_bgn[best, ],
  bgn.hiv = draws$base_bgn_hiv[best, ],
  bgn.hiv.time = draws$base_bgn_arv[best, ],
  med.time = draws$base_slope_med[best, ],
  med.hiv = draws$base_med_hiv[best, ],
  med.hiv.time = draws$base_med_arv[best, ],
  shp.time = draws$base_slope_shp[best, ]
)
write.csv(reff, "bf-pars-reff.csv", row.names = FALSE)

#' ## Fit plots

hiv_lab <- c("negative", "positive")
model <- expand.grid(t = seq_along(months), j = surveys$j, h = 1:2) |>
  mutate(month = months[t],
         hiv = hiv_lab[h],
         est = draws$propbf[cbind(best, t, j, h)],
         lower = apply(draws$propbf, 2:4, quantile, 0.025)[cbind(t, j, h)],
         upper = apply(draws$propbf, 2:4, quantile, 0.975)[cbind(t, j, h)]) |>
  left_join(surveys, by = "j")

obs <- mutate(dat, month = months[age])

pdf("bf-fit-surveys.pdf", width = 8, height = 3.5)
for (jj in surveys$j) {
  s <- surveys[surveys$j == jj, ]
  p <- ggplot(filter(model, j == jj), aes(month, est, colour = hiv, fill = hiv)) +
    geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.2, colour = NA) +
    geom_line() +
    geom_pointrange(data = filter(obs, j == jj),
                    aes(y = value, ymin = lower, ymax = upper),
                    colour = "black", size = 0.2) +
    facet_wrap(~hiv) +
    scale_x_continuous(breaks = seq(0, 36, 6), limits = c(0, 36)) +
    scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
    scale_colour_manual(values = c(negative = "#0066ff", positive = "#cc3366"),
                        aesthetics = c("colour", "fill")) +
    labs(title = sprintf("%s %s %s (%s)", s$country_name, s$survey_year_label,
                         s$survey_type, s$survey_id),
         x = "Months since last birth", y = "Breastfeeding") +
    theme_minimal() +
    theme(legend.position = "none")
  print(p)
}
dev.off()
