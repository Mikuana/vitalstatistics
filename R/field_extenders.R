#' Birth Data Field Extender
#'
#' The births data set has numerous useful attributes that can be derived from the data that is included in the binary. However, because this data set is already very large, in the name of saving storage space for the package, and memory when loading this data set for analysis, only the bare minimum of information that is necessary to derive other useful columns is included.
#'
#' As a convenience for accessing these columns, the package includes formulas to derive them. These formulas only take one argument, as they are not meant to be customized to any degree.
#'
#' @param births_data this raw births data set, or a transformation of it (but be aware that any changes may alter the results of these calculations)
#' @return a data frame with the newly applied calculated field
#'
#' @export
ext_birth_weekday = function(births_data) {
    dplyr::mutate_(births_data,
        birth_weekday = 'lubridate::wday(birth_weekday_date, label=TRUE)'
    )
}

#' @rdname ext_birth_weekday
#' @export
ext_birth_month = function(births_data) {
    dplyr::mutate_(births_data,
        birth_month = 'lubridate::month(birth_month_date, label=TRUE)'
    )
}

#' @rdname ext_birth_weekday
#' @export
ext_birth_year = function(births_data) {
    dplyr::mutate_(births_data,
        birth_year = 'lubridate::year(birth_month_date)'
    )
}

#' @rdname ext_birth_weekday
#' @export
ext_birth_decade = function(births_data) {
    dplyr::mutate_(births_data,
        birth_decade = 'ordered(paste0(floor((lubridate::year(birth_month_date)) / 10) * 10, "s"))'
    )
}

#' Birth Data Field Extender Suites
#'
#' As an additional convenience to the calculated column field extender formulas, this package includes formulas to wrap certain collections of these formulas into a suite which can be applied in a single call.
#'
#' @param births_data this raw births data set, or a transformation of it (but be aware that any changes may alter the results of these calculations)
#' @return a data frame with the newly applied calculated fields
#' 
#' @export
ext_suite_birth_date = function(births_data) {
    births_data %>%
        ext_birth_decade %>%
        ext_birth_year %>%
        ext_birth_month %>%
        ext_birth_weekday
}
