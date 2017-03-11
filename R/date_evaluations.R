#' Calendar Month Artifact Weight
#'
#' The purpose of this function is to provide a weight which can be used to adjust
#' values that are aggregated at the monthly level so that the noise caused by unequal
#' intervals (i.e varying number of days in each month) is muted.
#'
#' Divide the equal interval month value (1/12) by the actual share of the month
#' in the year that The month and year for this calculation are obtained by the
#' provided date variable. This calculation accounts for leap (366 day) years when
#' they occur.
#' 
#' This function is vectorized.
#'
#' @param month_date - A date that represents the month which a value is aggregated to
#' @return A weighting value which can be used to smooth the noise caused by the Julian calendar
#'
#' @export
cmaw = function(month_date) {
    func = Vectorize(cmaw_ind, vectorize.args="month_date")
    func(month_date)
}

cmaw_ind = function(month_date) {
    cmaw_date_catch(month_date)

    (1/12) /
    (lubridate::days_in_month(month_date) /
        ifelse(lubridate::leap_year(month_date), 366, 365)
    ) %>%
    cmaw_strip_attr
}

cmaw_strip_attr = function(cmaw_calc) {
    # coerces result to numeric in order to remove month name attribute from return
    as.numeric(cmaw_calc)
}

cmaw_date_catch = function(cmaw_input) {
    if(!lubridate::is.Date(cmaw_input) | is.na(cmaw_input)) {
        stop("You did not pass a value that lubridate recognizes as a date") # nocov
    }
}
