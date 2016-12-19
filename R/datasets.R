#' US Birth Certificate 
#'
#' The primary analytic data set that is included in this package. This data frame
#' is the result of the raw data processing that is applied to birth certificate
#' data sets provided by the CDC.
#' 
#' \strong{pseudo_birth_date}: a date field which represents the year and month
#' of birth, with the day of the month fixed to the first day of the month. This
#' is due to the fact that we cannot be any more precise with this public data set.
#' We include this along with factor representations of the birth year and month
#' as separate fields, since it can be useful to have an actual date field value.
#' 
#' \strong{birth_year}: an ordered factor representing the year of birth.
#' 
#' \strong{birth_month}: an ordered factor representing the month of the birth.
#' 
#' \strong{birth_state}: a factor representing the state where the birth occured.
#' This dimension stopped being reported by the CDC after 2004 due to privacy concerns,
#' and all records after that point are marked as NA.
#' 
#' \strong{birth_in_hospital}: a logical representation of whether the birth occured
#' in a hospital. Missing records are represented by NA.
#' 
#' \strong{cesarean}: a logical representation of whether the birth occured via
#' cesarean section. In cases where the method of birth is unknown, the record is
#' represented with an NA. Birth method is not reported in records prior to 1989,
#' so all earlier records are represented as NA.
#' 
#' \strong{cases}: an integer representing the number of birth records that are
#' represented by the combination of dimensions that are present in a particular
#' record of the births data set. All math that is performed on this data set should
#' be weighted by this value.
#'
#' @docType data
#'
#' @usage births
#'
#' @format An object of class \code{\link{data.frame}}
#'
#' @keywords datasets
#'
#' @source CDC and this package
#' 
#' @examples
#' # Load data directly from the vitalstatistics namespace
#' vitalstatistics::births
#' 
#' # Or first load the entire package
#' library(vitalstatistics)
#' births
#'
"births"


#' Cesarean rates by risk: United States, 1990–2012 and preliminary 2013
#'
#' A table of cesarean section counts and rates between 1990 and 2013 using birth
#' certificate records.
#'
#' @docType data
#'
#' @usage CDC_cesarean_2013
#'
#' @format An object of class \code{\link{data.frame}}
#'
#' @keywords datasets
#'
#' @source \href{http://www.cdc.gov/nchs/data/nvsr/nvsr63/nvsr63_06.pdf}{Trends in 
#' Low-risk Cesarean Delivery in the United States, 1990–2013}
#' 
#' Table A, National Vital Statistics Reports Volume 63, Number 6 November 5, 2014
#' 
#' by Michelle J.K. Osterman, M.H.S.; and Joyce A. Martin, M.P.H., Division of Vital 
#' Statistics
#' 
#' @examples
#' # Load data directly from the vitalstatistics namespace
#' vitalstatistics::CDC_cesarean_2013
#' 
#' # Or first load the entire package
#' library(vitalstatistics)
#' CDC_cesarean_2013
#'
"CDC_cesarean_2013"


#' Cesarean rates by age: United States, 1965-86
#'
#' A table of cesarean section rates between 1965 and 1986, with a breakdown by
#' maternal age. These rates are calculated with data collected via the National 
#' Hospital Discharge Survey.
#'
#' @docType data
#'
#' @usage HHS_cesarean_1989
#'
#' @format An object of class \code{\link{data.frame}}
#'
#' @keywords datasets
#'
#' @source \href{https://www.cdc.gov/nchs/data/series/sr_13/sr13_101.pdf}{Trends
#' in Hospital Utilization: United States, 1965-86}
#' 
#' Table 16. Vital and Health Statistics, Series 13, Number 101, September 1989
#'
#' Pokras R, Kozak LJ, McCarthy E, Graves EJ. National Center for Health Statistics.
#' 
#' @examples
#' # Load data directly from the vitalstatistics namespace
#' vitalstatistics::HHS_cesarean_1989
#' 
#' # Or first load the entire package
#' library(vitalstatistics)
#' HHS_cesarean_1989
#'
"HHS_cesarean_1989"


#' Cesarean rates by age: United States, 1988-92
#'
#' A table of cesarean section rates between 1980 and 1992, with a breakdown by
#' maternal age. These rates are calculated with data collected via the National 
#' Hospital Discharge Survey.
#'
#' @docType data
#'
#' @usage HHS_cesarean_1996
#'
#' @format An object of class \code{\link{data.frame}}
#'
#' @keywords datasets
#'
#' @source \href{http://www.cdc.gov/nchs/data/series/sr_13/sr13_124.pdf}{Trends
#' in Hospital Utilization: United States, 1988–92}
#' 
#' Table 26. Vital and Health Statistics, Series 13, Number 124, June 1996
#'
#' Gillum BS, Graves EJ, Kozak LJ. National Center for Health Statistics.
#' 
#' @examples
#' # Load data directly from the vitalstatistics namespace
#' vitalstatistics::HHS_cesarean_1996
#' 
#' # Or first load the entire package
#' library(vitalstatistics)
#' HHS_cesarean_1996
#'
"HHS_cesarean_1996"
