// Breastfeeding duration by maternal HIV status: joint model across surveys.
//
// Vendored from InfantFeedingAnalysis (Rob Glaubius, Avenir Health, MIT licence)
// https://github.com/rlglaubius/InfantFeedingAnalysis, commit 7a18b95.
// Only change: old `real x[n]` array declarations rewritten to `array[n] real x`
// (removed from Stan >= 2.33). Model is otherwise identical.

data {
  int<lower=0> n_surveys;
  int<lower=0> n_countries;
  int<lower=0> n_regions;
  int<lower=0> n_months;

  array[n_months] real<lower=0> month;         // months since last birth (observation time points)
  array[n_surveys] int<lower=0> country;       // maps surveys to countries. This must use values 1...n_countries.
  array[n_surveys] int<lower=0> region;        // maps surveys to regions of sub-Saharan Africa. This must use values 1...n_regions.
  array[n_surveys] real<lower=0> survey_year;  // year when survey conducted
  real ref_year;                               // time effects applied as effect * (survey_year[s] - ref_year)

  array[n_months,n_surveys,2] real<lower=0> X; // survey-weighted number of women who were not breastfeeding (X[,,1], HIV-; X[,,2], HIV+)
  array[n_months,n_surveys,2] real<lower=0> Y; // survey-weighted number of women who were breastfeeding (X[,,1], HIV-; X[,,2], HIV+)
}

parameters {
  array[n_regions] real base_bgn_hiv;
  array[n_regions] real base_med_hiv;

  array[n_regions] real base_bgn_arv;
  array[n_regions] real base_med_arv;

  array[n_regions] real base_slope_bgn;
  array[n_regions] real base_slope_med;
  array[n_regions] real base_slope_shp;

  array[n_countries] real<lower=0,upper=1> ceff_bgn;
  array[n_countries] real ceff_med;
  array[n_countries] real ceff_shp;
}

transformed parameters {
  array[n_surveys,2] real<lower=0,upper=1> u;
  array[n_surveys,2] real m;
  array[n_surveys,2] real s;
  array[n_months,n_surveys,2] real<lower=0,upper=1> propbf;

  for (j in 1:n_surveys) {
    // HIV-negative mothers
    u[j,1] = inv_logit(logit(ceff_bgn[country[j]]) + base_slope_bgn[region[j]] * (survey_year[j] - ref_year));
    m[j,1] = exp(ceff_med[country[j]] + base_slope_med[region[j]] * (survey_year[j] - ref_year));
    s[j,1] = exp(ceff_shp[country[j]] + base_slope_shp[region[j]] * (survey_year[j] - ref_year));

    // HIV-positive mothers
    u[j,2] = inv_logit(logit(ceff_bgn[country[j]]) + base_slope_bgn[region[j]] * (survey_year[j] - ref_year) + (base_bgn_hiv[region[j]] + base_bgn_arv[region[j]] * (survey_year[j] - ref_year)));
    m[j,2] = exp(ceff_med[country[j]] + base_slope_med[region[j]] * (survey_year[j] - ref_year) + (base_med_hiv[region[j]] + base_med_arv[region[j]] * (survey_year[j] - ref_year)));
    s[j,2] = exp(ceff_shp[country[j]] + base_slope_shp[region[j]] * (survey_year[j] - ref_year));
    for (t in 1:n_months) {
      propbf[t,j,1] = u[j,1] * (1.0 - 1.0 / (1.0 + (month[t] / m[j,1])^-s[j,1]));
      propbf[t,j,2] = u[j,2] * (1.0 - 1.0 / (1.0 + (month[t] / m[j,2])^-s[j,2]));
    }
  }
}

model {
  // Prior

  // Likelihood
  for (j in 1:n_surveys) {
    for (t in 1:n_months) {
      for (h in 1:2) {
        target += Y[t,j,h] * log(propbf[t,j,h]) + X[t,j,h] * log(1.0 - propbf[t,j,h]);
      }
    }
  }
}
