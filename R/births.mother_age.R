#' Mother's Age at Birth
#'
#' An integer field which represents the mother's age at time of birth in single year increments.
#'
#' This field is available for all years, but has undergone significant changes throughout the
#' history of the data set, which requires complex handling. As a result the range of ages that are
#' allowed in the data set change somewhat erratically over time. Additionally, it should be noted
#' that this field is a mixture of self reported (by the mother) data, and imputed data, and there
#' are some some drawbacks to mixing self reported and imputed data.
#'
#' The first maternal age field named UMAGERPT/DMAGERPT and was collected between 1968 and 2003 with
#' maternal age reported in single years. From 1992 to 2003, this field was largely unpopulated
#' (approximately 98% missing). It appears that the DMAGE field which was collected between 1989 and
#' 2002 was used to fill this gap. The DMAGE field is delineated from UMAGERPT/DMAGERPT because the
#' former explicitly acknowledges that missing data will be imputed through the use of date of
#' birth, whereas the latter makes no such explanation in the data dictionaries. In 2003, DMAGE was
#' no longer reported but a recoded value named MAGER41 - which obfuscates births for mothers
#' younger than 15 and older than 50 - became available to fill most of these missing values.
#' MAGER41 lasted only a single year though,  and in 2004 a recoded value known as MAGER - which
#' obfuscates births to mothers younger than 13 and older than 50 - was introduced and remains in
#' effect through the end of the data sets.
#'
#' @section Data Quality Tests:
#'
#' This column is tested for the following quality assumptions prior to packaging:
#' \enumerate{
#'   \item NA
#' }
#'
#' @return a \code{\link{integer}} column
#' @seealso \code{\link{births}}
#' @family births-column
#' @name mother_age
NULL
