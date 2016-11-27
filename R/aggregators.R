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
