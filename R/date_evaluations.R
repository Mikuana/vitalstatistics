#' Calendar Month Artifact Weight
#'
#' The purpose of this function is to provide a weight which can be used to adjust values that are
#' aggregated at the monthly level so that the noise caused by unequal intervals (i.e varying number
#' of days in each month) is muted.
#' 
#' Divide the equal interval month value (1/12) by the actual share of the month in the year that
#' The month and year for this calculation are obtained by the provided date variable. 
#' This calculation accounts for leap (366 day) years when they occur.
#' 
#' @param month_date - A date that represents the month which a value is aggregated to
#' @return A weighting value which can be used to smooth the noise caused by the Julian calendar
#' @examples
#'  # determine the appropriate weighting for volumes in February 2016
#' 
#'  x = cmaw(as.Date('2016-02-01')
#'  print(x)
#'  1.048851
#' 
#'  # then apply this weighting to volume values to get a scaled value
#' 
#'  32000 * x
#'  33563.22
#' 
#' @export
cmaw = function(month_date) {
    if(!lubridate::is.Date(month_date)) {
        stop("You did not pass a value that lubridate recognizes as a date")
    }

    (1/12) / 
        (lubridate::days_in_month(month_date) / ifelse(lubridate::leap_year(month_date), 366, 365))
}


# #' Birth Volume Seasonal Adjustment
# #' @export
# seas_birth_adj = function(month_date) {
#     if(!lubridate::is.Date(month_date)) {
#         stop("You did not pass a value that lubridate recognizes as a date")
#     }
    
    
#     `__seas__` <<- births dplyr::%>% 
#         dplyr::group_by dplyr::%>%
#         dplyr::transmute(cases = cases * cmaw(month_date)) dplyr::%>%
#         stats::ts(frequency=12, start=1968) %>%
#         stats::decompose(type="multiplicative")
# }
