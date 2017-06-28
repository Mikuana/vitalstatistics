#' Birth State
#'
#' A factor column describing the state or territory where the birth occurred.
#'
#' From 1968 to 2004 the public data sets included the state (or territory) where the birth
#' occurred. After 2004, state of occurrence is no longer included, presumably for privacy reasons.
#' This field include all 50 states, and the District of Columbia (i.e. Washington D.C.).
#'
#' The field includes placeholder levels for Puerto Rico, the Virgin Islands, and Guam, but due to
#' the way that the raw data are processed, there are no records for these territories. In future
#' development, this may be changed so that they are included.
#'
#' @section Data Quality Tests:
#'
#' This column is tested for the following quality assumptions prior to packaging:
#' \enumerate{
#'   \item all 51 states (including D.C.) are represented in expected years
#'   \item there are no missing values in expected years
#'   \item no states are represented after 2004
#'   \item territories have no records at any time
#' }
#'
#' @return a \code{\link{factor}} column
#' @seealso \code{\link{births}}
#' @family births-column
#' @name birth_state
NULL
