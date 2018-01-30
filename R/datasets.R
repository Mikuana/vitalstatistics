#' Vital Statistics Data into Feathers
#'
#' Exports all data sets included in this package into the feather format. This is intended for use
#' by the Python pandas package.
#'
#' @name featherize
featherize = function() {
  rp = file.path('..', 'VitalStories', 'templates', 'VitalStatistics')

  feather::write_feather(births, file.path(rp, 'births.feather'))
  feather::write_feather(HHS_cesarean_1989, file.path(rp, 'HHS_cesarean_1989.feather'))
  feather::write_feather(HHS_cesarean_1989, file.path(rp, 'HHS_cesarean_1996.feather'))
  feather::write_feather(HHS_cesarean_1989, file.path(rp, 'CDC_cesarean_2013.feather'))

  # for(rd in list_files_with_exts('man', 'Rd')) {
  #   fp = rd %>% basename %>% file_path_sans_ext %>% paste0('.html') %>% file.path(rp, .)
  #   Rd2txt(rd, out=fp, Rd2txt_options(code_quote=FALSE, underline_titles=FALSE))
  # }
}


#' Cesarean rates by risk: United States, 1990-2012 and preliminary 2013
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
#' Low-risk Cesarean Delivery in the United States, 1990-2013}
#'
#' Table A, National Vital Statistics Reports Volume 63, Number 6 November 5, 2014
#'
#' by Michelle J.K. Osterman, M.H.S.; and Joyce A. Martin, M.P.H., Division of Vital
#' Statistics
#' @name CDC_cesarean_2013
NULL


#' Cesarean rates by age: United States, 1965-86
#'
#' A table of cesarean section rates between 1965 and 1986, with a breakdown by maternal age. These
#' rates are calculated with data collected via the National  Hospital Discharge Survey.
#'
#' @docType data
#'
#' @usage HHS_cesarean_1989
#'
#' @format An object of class \code{\link{data.frame}}
#'
#' @keywords datasets
#'
#' @source \href{https://www.cdc.gov/nchs/data/series/sr_13/sr13_101.pdf}{Trends in Hospital
#'   Utilization: United States, 1965-86}
#'
#'   Table 16. Vital and Health Statistics, Series 13, Number 101, September 1989
#'
#'   Pokras R, Kozak LJ, McCarthy E, Graves EJ. National Center for Health Statistics.
#' @name HHS_cesarean_1989
NULL


#' Cesarean rates by age: United States, 1988-92
#'
#' A table of cesarean section rates between 1980 and 1992, with a breakdown by maternal age. These
#' rates are calculated with data collected via the National  Hospital Discharge Survey.
#'
#' @docType data
#'
#' @usage HHS_cesarean_1996
#'
#' @format An object of class \code{\link{data.frame}}
#'
#' @keywords datasets
#'
#' @source \href{http://www.cdc.gov/nchs/data/series/sr_13/sr13_124.pdf}{Trends in Hospital
#'   Utilization: United States, 1988-92}
#'
#'   Table 26. Vital and Health Statistics, Series 13, Number 124, June 1996
#'
#'   Gillum BS, Graves EJ, Kozak LJ. National Center for Health Statistics.
#' @name HHS_cesarean_1996
NULL
