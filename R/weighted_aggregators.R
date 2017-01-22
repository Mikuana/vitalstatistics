#' Logical Field Rate Calculation
#'
#' Calculate a rate using a logical field, with TRUE as the numerator, and TRUE/FALSE as the denominator. This excludes NA values. When provided, the results of each are multiplied by the cases parameter, which allows us to appropriately scale the calculations for our reduced record data sets that are included in the package'
#'
#' @param field - A name of a logical table field name that will be aggregated
#' @param cases - A value that should be applied to the result in order to simulate
#' a number of records with this result.
#' @return A formula that can be executed in a dplyr summarize statement
#' @examples
#'  library(dplyr)
#'  births %>%
#'      filter(DOB_YY >= 1989) %>%
#'      group_by(DOB_YY) %>%
#'      summarize(
#'          cesarean_rate = lg_rate(cesarean_lg, cases)()
#'      ) %>%
#'      plot
#' @export
rate_lg = function(field, cases=1) {
    function(f=field, c=cases) {
        sum(f * c, na.rm=TRUE) / sum((!is.na(f)) * c)
    }
}

#' Weighted Aggregate Strings
#'
#' A set of functions that act as a convenience wrapper to generate a formulas for calculating aggregates of a data frame which requires weighting. This formula is intended to be used in a dplyr summarize_ or mutate_ formula. The defaults are intended for use with the births data set, using the 'cases' field as the default weighting value.
#'
#' @param column in the case of aggregates which function on non-numeric columns, this is the column that is used
#' @param numeric_column in the case of numeric aggregation functions (mean, SD), this is the column that is used to aggregate
#' @param weight_column the value that each value is weighted by in calculation of the aggregate
#' @param na.rm a logical indicator of whether NA values should be removed prior to aggregation
#' @param q the quantile value that you desire
#' @param .summ a logical control for whether to use already calculated values for Mean and SD in the data.frame. This is intended for use in a summary function, where quantile values are calculated alongside a Mean and SD value. This prevents the quantile function from recalculating the Mean and SD multiple times.
#'
#' @return a formula string that can be executed in a dplyr summarize_ statement
#' @examples
#'  summarize_(births, age_mean = wtd_mean('mother_age_int', na.rm=TRUE))
#' @export
wtd_mean = function(numeric_column, weight_column='cases', na.rm=FALSE) {
    paste('matrixStats::weightedMean(',numeric_column,',',weight_column,', na.rm=',na.rm,')')
}

#' @rdname wtd_mean
#' @export
wtd_median = function(numeric_column, weight_column='cases', na.rm=FALSE) {
    paste('matrixStats::weightedMedian(',numeric_column,',',weight_column,', na.rm=',na.rm,')')
}

#' @rdname wtd_mean
#' @export
wtd_SD = function(numeric_column, weight_column='cases', na.rm=FALSE) {
    paste('matrixStats::weightedSd(',numeric_column,',',weight_column,', na.rm=',na.rm,')')
}

#' @rdname wtd_mean
#' @export
wtd_quantile = function(numeric_column, q, weight_column='cases', na.rm=FALSE, .summ=FALSE) {
    if(.summ) {
        paste('stats::qnorm(',q,') * SD + Mean')
    } else {
        paste('stats::qnorm(',q,') * ',
              wtd_SD(numeric_column, weight_column, na.rm), ' + ',
              wtd_mean(numeric_column, weight_column, na.rm)
        )
    }
}

#' @rdname wtd_mean
#' @export
wtd_count = function(column, weight_column='cases') {
    paste('base::sum(base::ifelse(base::is.na(',column,'),0,',weight_column,'))')
}

#' @rdname wtd_mean
#' @export
wtd_NA_count = function(column, weight_column='cases') {
    paste('base::sum(base::ifelse(base::is.na(',column,'),',weight_column,',0))')
}

#' Numeric Value Summary of Weighted Records
#'
#' Because the \code{\link{vitalstatistics::births}} data set uses a weighted record strategy (i.e. you have to multiply everything by the cases field), the typical summary function won't return meaningful results. In order to provide some basic descriptive statistics for a numeric column in the data set, this function can be used instead.
#'
#' It makes use of the dplyr format for summarizing results, and therefore integrates nicely with a chain of dplyr functions. Under the hood, it is using \code{\link{dplyr::summarize_}} and pasting strings together for evaluation, with the actual statistics being handled by the \code{\link{matrixStats}} package, based upon your input.
#'
#' @param data - a data frame, presumably the births data set or a derivative
#' @param column - the numeric column that you want to perform summary statistics on
#' @param weight - the column in the data.frame that contains the weighting value
#' @param na.rm - whether to pass a TRUE or FALSE value to the na.rm argument for each underlying aggregation function.
#' @return A formula that can be executed in a dplyr summarize statement
#' @examples
#'  library(dplyr)
#'  library(vitalstatistics)
#'  births %>% numeric_summary('mother_age_int', na.rm=TRUE)
#'
#' @export
numeric_summary = function (data, numeric_column, weight_column='cases', na.rm=FALSE) {
    summarize_(data,
       `Mean`    = wtd_mean(numeric_column=numeric_column, na.rm=na.rm),
       `SD`      = wtd_SD(numeric_column=numeric_column, na.rm=na.rm),
       `Min.`    = paste('base::min(',numeric_column,', na.rm=',na.rm,')'),
       `1st Qu.` = wtd_quantile(numeric_column=numeric_column, 0.25, na.rm=na.rm, .summ=TRUE),
       `Median`  = wtd_median(numeric_column=numeric_column, na.rm=na.rm),
       `3rd Qu.` = wtd_quantile(numeric_column=numeric_column, 0.75, na.rm=na.rm, .summ=TRUE),
       `Max.`    = paste('base::max(',numeric_column,', na.rm=',na.rm,')'),
       `Count`   = wtd_count(column=numeric_column, weight_column=weight_column),
       `NA`      = wtd_NA_count(column=numeric_column, weight_column=weight_column)
    )
}
