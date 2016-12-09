#' @importFrom stats pf
#' @title Two sample t test
#' @description \code{two_sample_test} tests that \code{y} has the same mean
#' within the two groups defined by \code{x}
#' @param x grouping variable; object of type \code{factor}
#' @param y a \code{numeric} vector
#' @param confint confidence level
#' @param alternative a character string specifying the alternative hypothesis,
#' must be one of "both" (default), "greater", "less" or "all". You can specify
#' just the initial letter.
#' @return \code{two_sample_test} returns an object of class \code{"two_sample_test"}.
#' An object of class \code{"two_sample_test"} is a list containing the
#' following components:
#'
#' \item{levels}{levels of \code{x}}
#' \item{obs}{number of observations of \code{y} for each level of \code{x}}
#' \item{n}{total number of observations}
#' \item{mean}{mean of \code{y} for each level of \code{x}}
#' \item{sd}{standard deviation of \code{y} for each level of \code{x}}
#' \item{se}{estimate of standard error of \code{y} for each level of \code{x}}
#' \item{lower}{lower limit for the mean of \code{y} for each level of \code{x}}
#' \item{upper}{upper limit for the mean of \code{y} for each level of \code{x}}
#' \item{combined}{a data frame; mean, standard deviation, standard error and
#' confidence limit of mean of \code{y}}
#' \item{mean_diff}{difference in mean of \code{y} for the two groups of \code{x}}
#' \item{se_dif}{estimate of the standard error for difference in mean of
#' \code{y} for the two groups of \code{x}} \item{sd_dif}{degrees of freedom}
#' \item{conf_diff}{confidence interval for \code{mean_diff}}
#' \item{df_pooled}{degrees of freedom for the pooled method}
#' \item{df_satterthwaite}{degrees of freedom for the Satterthwaite method}
#' \item{t_pooled}{t statistic for the pooled method}
#' \item{t_satterthwaite}{t statistic for the Satterthwaite method}
#' \item{sig_pooled}{two-sided p-value for the pooled method}
#' \item{sig_pooled_l}{lower one-sided p-value for the pooled method}
#' \item{sig_pooled_u}{upper one-sided p-value for the pooled method}
#' \item{sig}{two-sided p-value for the Satterthwaite method}
#' \item{sig_l}{lower one-sided p-value for the Satterthwaite method}
#' \item{sig_u}{upper one-sided p-value for the Satterthwaite method}
#' \item{num_df}{numerator degrees of freedom for folded f test}
#' \item{den_df}{denominator degrees of freedom for folded f test}
#' \item{f}{f value for the equality of variances test}
#' \item{f_sig}{p-value for the folded f test}
#' \item{var_y}{name of \code{y}}
#' \item{confint}{confidence level}
#' \item{alternative}{alternative hypothesis}
#'
#' @examples
#' two_sample_test(mtcars$mpg, mtcars$am, type = 'less')
#' paired_ttest(mtcars$mpg, mtcars$am, type = 'greater')
#' paired_ttest(mtcars$mpg, mtcars$am, type = 'both')
#' paired_ttest(mtcars$mpg, mtcars$am, type = 'all')
#' @export
#'
two_sample_test <- function(data, x, y, confint = 0.95,
  alternative = c('both', 'less', 'greater', 'all')) UseMethod('two_sample_test')

#' @export
#'
two_sample_test.default <- function(data, x, y, confint = 0.95,
  alternative = c('both', 'less', 'greater', 'all')) {

  var_y <- y
  h <- data_split(data, x, y)
  alpha <- 1 - confint
  a <- alpha / 2
  h <- mutate(h,
          df = length - 1,
          error = round(qt(a, df), 3) * -1,
          lower = round(mean_t - (error * std_err), 3),
          upper = round(mean_t + (error * std_err), 3)
  )
  grp_stat <- h
  means <- grp_stat[, 3]
  g_stat <- as.matrix(h)

  comb <- da(data, y)
  comb <- mutate(comb,
          df = length - 1,
          error = round(qt(a, df), 3) * -1,
          lower = round(mean_t - (error * std_err), 3),
          upper = round(mean_t + (error * std_err), 3)
  )


  names(comb) <- NULL
  n1 <- grp_stat[1, 2]
  n2 <- grp_stat[2, 2]
  n <- n1 + n2
  mean_diff <- means[1] - means[2]
  sd1 <- round(grp_stat[1, 4], 3)
  sd2 <- round(grp_stat[2, 4], 3)
  s1 <- round(grp_stat[1, 4] ^ 2, 3)
  s2 <- round(grp_stat[2, 4] ^ 2, 3)
  sd_dif <- round(sd_diff(n1, n2, s1, s2), 3)
  se_dif <- round(se_diff(n1, n2, s1, s2), 3)
  conf_diff <- round(conf_int_p(mean_diff, se_dif, alpha = alpha), 3)


  d_f <- as.vector(df(n1, n2, s1, s2))
  t <- round(mean_diff / (((s1 / n1) + (s2 / n2)) ^ 0.5), 4)
  sig_l <- round(pt(t, d_f), 4)
  sig_u <- round(1 - pt(t, d_f), 4)
  sig <- round(pt(t, d_f) * 2, 4)
  se <- se_sw(s1, s2, n1, n2)
  err_mar <- se * -qt(0.025, 170)
  con_lower <- mean_diff - err_mar
  con_upper <- mean_diff + err_mar


  df_pooled <- (n1 + n2) - 2
  t_pooled <- round(mean_diff / se_dif, 4)
  sig_pooled_l <- round(pt(t_pooled, df_pooled), 4)
  sig_pooled_u <- round(1 - pt(t_pooled, df_pooled), 4)
  sig_pooled <- round(pt(t_pooled, df_pooled) * 2, 4)
  error_margin <- se_dif * -qt(0.025, 198)
  conf_lower <- mean_diff - error_margin
  conf_upper <- mean_diff + error_margin
  temp <- c(conf_lower, conf_upper)

  result <- list(levels           = g_stat[, 1],
                 obs              = g_stat[, 2],
                 n                = n,
                 mean             = g_stat[, 3],
                 sd               = g_stat[, 4],
                 se               = g_stat[, 5],
                 lower            = g_stat[, 8],
                 upper            = g_stat[, 9],
                 combined         = comb,
                 mean_diff        = mean_diff,
                 sd_dif           = sd_dif,
                 se_dif           = se_dif,
                 conf_diff        = conf_diff,
                 df_pooled        = df_pooled,
                 df_satterthwaite = d_f,
                 t_pooled         = t_pooled,
                 t_satterthwaite  = t,
                 sig_pooled_l     = sig_pooled_l,
                 sig_pooled_u     = sig_pooled_u,
                 sig_pooled       = sig_pooled,
                 sig              = sig,
                 sig_l            = sig_l,
                 sig_u            = sig_u,
                 num_df           = n1 - 1,
                 den_df           = n2 - 1,
                 f                = round(s1 / s2, 4),
                 f_sig            = round((1 - pf(round(s1 / s2, 4), (n1 - 1), (n2 -1))) * 2, 4),
                 var_y            = var_y,
                 confint          = confint,
                 alternative      = alternative)

  class(result) <- 'two_sample_test'
  return(result)

}

#' @export
#'
print.two_sample_test <- function(x, ...) {
  print_two_ttest(x)
}