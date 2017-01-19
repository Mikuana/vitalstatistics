#' Logical Field Rate Calculation
#'
#' Calculate a rate using a logical field, with TRUE as the numerator, and TRUE/FALSE
#' as the denominator. This excludes NA values. When provided, the results of each
#' are multiplied by the cases parameter, which allows us to appropriately scale 
#' the calculations for our reduced record data sets that are included in the package'
#' 
#' This function returns a function, meant to be applied during a dplyr summarize
#' statement, although it can be used in a broader context. Because the function
#' returns a function, it is important to follow the parameters with parenthesis
#' '()' in order to execute the function that is returned.
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
numeric_summary = function (data, column, weight='cases', na.rm=FALSE) {
    dplyr::summarize_(
        data,
        `Mean`    = paste('matrixStats::weightedMean(',column,',',weight,', na.rm=',na.rm,')'),
        `SD`      = paste('matrixStats::weightedSd(',column,',',weight,', na.rm=',na.rm,')'),
        `Min.`    = paste('base::min(',column,', na.rm=',na.rm,')'),
        `1st Qu.` = 'stats::qnorm(0.25) * SD + Mean',
        `Median`  = paste('matrixStats::weightedMedian(',column,',',weight,', na.rm=',na.rm,')'),
        `3rd Qu.` = 'stats::qnorm(0.75) * SD + Mean',
        `Max.`    = paste('base::max(',column,', na.rm=',na.rm,')'),
        `Count`   = paste('base::sum(base::ifelse(base::is.na(',column,'),0,',weight,'))'),
        `NA`      = paste('base::sum(base::ifelse(base::is.na(',column,'),',weight,',0))')
    )
}
