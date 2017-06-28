#' Birth Data Field Extender
#'
#' The births data set has numerous useful attributes that can be derived from the data that is
#' included in the binary. However, because this data set is already very large, in the name of
#' saving storage space for the package, and memory when loading this data set for analysis, only
#' the bare minimum of information that is necessary to derive other useful columns is included.
#'
#' As a convenience for accessing these columns, the package includes formulas to derive them. These
#' formulas only take one argument, as they are not meant to be customized to any degree. One
#' important thing to note is that these extensions will only work if you've created a copy of the
#' births dataset. This is best done using the \code{\link[data.table]{copy}} function on the births
#' table.
#'
#' @param births_data this raw births data set, or a transformation of it (but be aware that any
#'   changes may alter the results of these calculations)
#' @return a data.table with the newly applied calculated field
#'
#' @examples
#' dt = data.table::copy(births)
#' ext.birth_weekday(dt)
#' dt
#'
#' @export
ext.birth_weekday = function(births_data) {
  births_data[,`:=`(birth_weekday = lubridate::wday(birth_weekday_date, label=TRUE))]
}

#' @rdname ext.birth_weekday
#' @export
ext.birth_month = function(births_data) {
  births_data[,`:=`(birth_month = lubridate::month(birth_month_date, label=TRUE))]
}

#' @rdname ext.birth_weekday
#' @export
ext.birth_year = function(births_data) {
  births_data[,`:=`(birth_year = lubridate::year(birth_month_date))]
}

#' @rdname ext.birth_weekday
#' @export
ext.birth_decade = function(births_data) {
  births_data[,`:=`(
    birth_decade = ordered(paste0(floor((lubridate::year(birth_month_date)) / 10) * 10, "s"))
  )][,`:=`(birth_decade = dplyr::recode(birth_decade, '1960s' = '1968/9'))]
}

#' Birth Data Field Extender Suites
#'
#' As an additional convenience to the calculated column field extender formulas, this package
#' includes formulas to wrap certain collections of these formulas into a suite which can be applied
#' in a single call.
#'
#' @param births_data this raw births data set, or a transformation of it (but be aware that any
#'   changes may alter the results of these calculations)
#' @return a data frame with the newly applied calculated fields
#'
#' @export
ext_suite.birth_date = function(births_data) {
  ext.birth_decade(births_data)
  ext.birth_year(births_data)
  ext.birth_month(births_data)
  ext.birth_weekday(births_data)
}
