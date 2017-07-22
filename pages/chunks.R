# This is our external R script called example.R
# We're adding two chunks variablesXY and plotXY

## @knitr page-defaults

knitr::opts_chunk$set(
  echo=FALSE,
  include=TRUE
)

ggplot2::theme_update(plot.background = ggplot2::element_rect(fill = "#fffff8"))
