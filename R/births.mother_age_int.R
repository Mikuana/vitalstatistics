#' Mother's Age at Birth
#'
#' A integer field which represents the mother's age at the time of birth in single year increments.
#'
#' This field is available for all years, but has undergone significant changes throughout the
#' history of the data sets which requires complex handling. As a result, the range of ages for
#' births in the data set changes somewhat erratically over time. Additionally, it should be noted
#' that this field is a mixture of self reported (by the mother) data, and imputed data.
#'
#' The first field named either or UMAGERPT/DMAGERPT was collected between 1968 and 2003 and
#' reported maternal age in single years. However, from 1992 to 2003, this field went largely
#' unpopulated. To fill in this gap, the DMAGE field which was collected between 1989 and 2002 is
#' used. The DMAGE field is delineated from others because it explicitly acknowledges that missing
#' data will be imputed through the use of date of birth. In 2003, DMAGE was no longer reported but
#' a recoded value named MAGER41 - which obfuscates births for mothers younger than 15 and older
#' than 50 - was available to fill most of these missing values. Finally, in 2004 a recoded value
#' known as MAGER - which obfuscates births to mothers younger than 13 and older than 50 - was
#' introduced and remains in effect through the end of the data sets.
#'
#' @section Data Quality Tests:
#'
#' This column is tested for the following quality assumptions prior to packaging:
#' \enumerate{
#'   \item NA
#' }
#'
#' @return a \code{\link{integer}} column
#' @seealso \code{\link{mother_age}} \code{\link{births}}
#' @family births-column
#' @name mother_age_int
NULL
