#' US Birth Certificate 
#'
#' The primary analytic data set that is included in this package. This data frame is the result of the raw data processing that is applied to birth certificate data sets provided by the CDC.
#' 
#' We include a description of each field in this data set, since they are the result of a quite complicated process which blends data from over 40 years of distinct data sets with different field values and usages.
#'
#' @section Conceptual Prefixes:
#' 
#' Each field is named with a conceptual prefix in order to make it more clear. This is useful to delineate fields that might be confusing, such as date of birth. If we were to simply use "date" as our field name, it leaves some question as to whether this is the date of birth, date of conception, date of reporting, etc. Instead, we use one of a defined set of words as the first word in every field to make the meaning clear.
#' 
#' \strong{birth}: fields prefixed with "birth_" describe values relative to the delivery event. For example, the "birth_hour" is intended to be the time when the delivery was completed, and "birth_in_hospital" refers to whether the final moment of the delivery occured in the hospital, regardless of the length of time that might have been spent in labor outside the hospital.
#' 
#' \strong{mother}: the mother is the primary subject addressed by this data set. Unless otherwise stated in the field definition, all dependent attributes of the mother should be considered in the context of the birth. For example, the age of the mother calculated at the time of the birth, her state of residence at the time of the birth, and so forth.
#' 
#' \strong{child}: the child (i.e. newly born infant) is the secondary subject addressed by this data set.
#' 
#' @section Fields:
#' 
#' \strong{birth_weekday_date}: a date type field which represents the specific month, year, and day of the week that the birth occurred. This is accomplished by setting the date value equal to the corresponding day of the week in the first full week of the month when the birth occured.
#' 
#' For example, if a birth occurred in January of 2014 on a Tuesday, we determine that the first full week of January starts on the 5th (i.e. Sunday, January 5th), and that the Tuesday of that week is 2014-01-07. Accordingly the birth_weekday_date value would be set to 2014-01-07. 
#' 
#' This field is useful because it can be used as a date value directly, while still representing the correct year, month, and day of the week that the birth occurred. It is important to note that this field does not represent the actual date of birth; day of month was reported until 1988, but was omitted from records after that time for privacy reasons.
#' 
#' \strong{birth_month_date}:a date type field which represents the specific month and year that the birth occurred. This date value is always set to the first day of the month, and serves as a substitute for the birth_weekday_date for records where the day of the week is not known.
#' 
#' \strong{birth_state}: a factor representing the state where the birth occured. This dimension stopped being reported by the CDC after 2004 due to privacy concerns, and all records after that point are marked as NA.
#' 
#' \strong{birth_in_hospital}: a logical representation of whether the birth occurred in a hospital. Missing records are represented by NA.
#' 
#' \strong{birth_via_cesarean}: a logical representation of whether the birth occured via cesarean section. In cases where the method of birth is unknown, the record  is represented with an NA. Birth method is not reported in records prior to 1989, so all earlier records are represented as NA.
#' 
#' \strong{mother_age_int}: an integer value which represents the age (in years) of the mother at the time of delivery.
#' 
#' \strong{mother_age}: a factor representation of the age (in years) of the mother at the time of delivery. This field differs from mother_age_int in that it uses banded values for ages 10-12 and 50-54. The tradeoff for the loss of precision is that this field is slightly better populated than mother_age_int.
#' 
#' \strong{child_sex}: a factor representation of the sex of the infant.
#' 
#' \strong{cases}: an integer representing the number of birth records that are represented by the combination of dimensions that are present in a particular record of the births data set. All math that is performed on this data set should be weighted by this value.
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
#' A table of cesarean section rates between 1965 and 1986, with a breakdown by maternal age. These rates are calculated with data collected via the National  Hospital Discharge Survey.
#'
#' @docType data
#'
#' @usage HHS_cesarean_1989
#'
#' @format An object of class \code{\link{data.frame}}
#'
#' @keywords datasets
#'
#' @source \href{https://www.cdc.gov/nchs/data/series/sr_13/sr13_101.pdf}{Trends in Hospital Utilization: United States, 1965-86}
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
#' A table of cesarean section rates between 1980 and 1992, with a breakdown by maternal age. These rates are calculated with data collected via the National  Hospital Discharge Survey.
#'
#' @docType data
#'
#' @usage HHS_cesarean_1996
#'
#' @format An object of class \code{\link{data.frame}}
#'
#' @keywords datasets
#'
#' @source \href{http://www.cdc.gov/nchs/data/series/sr_13/sr13_124.pdf}{Trends in Hospital Utilization: United States, 1988–92}
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
