#' Birth Weekday Date
#'
#' A date type field which represents the specific month, year, and day of the week that the birth
#' occurred.
#'
#' Prior to 1989, the actual day of month of the birth was provided with the dataset, but after that
#' day of month was removed and only day of the week was provided. We calculate the date value by
#' setting the day of month to the corresponding day of the week in the first full week of the month
#' when the birth occured.
#'
#' For example, if a birth occurred in January of 2014 on a Tuesday, we determine that the first
#' full week of January starts on the 5th (i.e. Sunday, January 5th), and that the Tuesday of that
#' week is 2014-01-07. Accordingly the birth_weekday_date value would be set to 2014-01-07.
#'
#' This field is useful because it can be used as a date value directly, while still representing
#' the correct year, month, and day of the week that the birth occurred. \emph{It is important to
#' note that this field does not represent the actual date of birth}; day of month was reported
#' until 1988, but was omitted from records after that time for privacy reasons.
#'
#' This field is entirely blank for births during the year of 1968, as no data were provided in that
#' data set. However, you can still make use of the \code{\link{birth_month_date}} field to
#' access year and month of birth.
#'
#' @section Data Quality Tests:
#'
#' This column is tested for the following quality assumptions prior to packaging:
#' \enumerate{
#'   \item less than 0.1% data missing (after 1968, which had no data for day of week)
#'   \item year and month dateparts match birth_month_date (when not NA)
#'   \item exactly 7 days are represented in each month
#'   \item at least one record exists for each month in every year
#' }
#'
#' @seealso \code{\link{birth_month_date}}
#'
#' @return a \code{\link{Date}} column
#' @family births-data
#' @name birth_weekday_date
NULL
