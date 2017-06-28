#' Birth Month Date
#'
#' A date type field which represents the specific month and year that the birth occurred.
#'
#' This date value is always set to the first day of the month. This is one of the fundamental
#' attributes of the data set, and has no missing values. The actual date is not provided directly
#' in the data set, but is instead calculated using the year and month fields and the 1st day of the
#' month. What this means is that the day value for this column should \emph{never} be used; it is
#' simply an arbitrary - but consistent - placeholder meant to simplify time based analysis.
#'
#' @section Data Quality Tests:
#'
#' This column is tested for the following quality assumptions prior to packaging:
#' \enumerate{
#'   \item no NA values
#'   \item all day of month values are equal to 1
#'   \item at least one record exists for each month in every year
#' }
#'
#' @return a \code{\link{Date}} column
#' @seealso \code{\link{birth_weekday_date}} \code{\link{births}}
#' @family births-column
#' @name birth_month_date
NULL
