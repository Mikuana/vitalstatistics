#' Birth In Hospital
#'
#' A logical field indicating whether the birth occurred within a hospital.
#'
#' This column is highly derived from the source data, as the data collected on birth facility type
#' have varied a great since 1968. From 1968 to 1977, the "Attendant at Birth" field tracked whether the
#' birth occurred within a hospital or institution, and if not it tracked the kind of provider that
#' attended the birth (physician or midwife). From 1975 to 1977, a new field was added which was more
#' specifically focused on place, rather than combining place and attending provider type into a
#' single field. From 1978 to 1988, a slight refinement of this place focused field was introduced.
#' And then finally in 1989 to most modern form of the field was introduced, which simply tracks
#' whether the birth occurred in a hospital, or not. To generate our logical column, we use a two
#' step process where all of these older fields are mapped to the values of the most recent (e.g.
#' "Births not in hospitals; Attended by physician' ~= "Not in Hospital"), and then converted into a
#' logical, within NA values for missing/unknown data.
#'
#' @section Data Quality Tests:
#'
#' This column is tested for the following quality assumptions prior to packaging:
#' \enumerate{
#'   \item non-NA values exist in each expected year
#' }
#'
#' @return a \code{\link{logical}} column
#' @seealso \code{\link{births}}
#' @family births-column
#' @name birth_in_hospital
NULL
