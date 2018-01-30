[![Build Status](https://travis-ci.org/Mikuana/vitalstatistics.svg?branch=master)](https://travis-ci.org/Mikuana/vitalstatistics) [![codecov](https://codecov.io/gh/Mikuana/vitalstatistics/branch/master/graph/badge.svg)](https://codecov.io/gh/Mikuana/vitalstatistics)

# Overview

The focus of this project is the analysis of birth data in the United States, although this could be described in a variety of different ways depending upon the intent of the user. This is an R-Package complete with data sets, documentation, and custom functions for analyzing birth certificate records, which are generally available in their raw form but also generally difficult to work with due to size or non-machine friendly formatting.

The data sets included in this package are primarily drawn from the Birth Data files made available by the CDC through their [Vital Stats Online](https://www.cdc.gov/nchs/data_access/vitalstatsonline.htm) portal. Data are derived from birth certificates reaching back to 1968.

# Installation

This package can be easily installed in R using the `devtools:install_github` function.

```r
# if you don't already have the devtools package install it
install.packages("devtools")

# then install this package, I recommend including dependencies=TRUE
devtools::install_github("Mikuana/vitalstatistics", dependencies=TRUE)
```

It is crucial to recognize that the `births` data set in this package is reduced from hundreds of millions of records using a simple dimensional record count strategy. This makes the table somewhat similar to a [OLAP Cube](https://en.wikipedia.org/wiki/OLAP_cube), and accordingly you cannot perform simple arithmetic but instead must always account for the `cases` field to obtain the correct result.

# Raw Data Processing

A key feature of this project is the ability to process the raw Birth Data files into analytic data sets that are more suitable for data science. This is achieved prior to the R package build, and therefore is unncessary to understand if the `births` data set is adequate for your purposes. If you need more you can get more, but it will require you to step outside of R and use several different tools. You can get started by looking at the [raw data readme](data-raw/README.md).

# Disclaimer

Use of this data strictly prohibits any attempts to identify individuals. This is described in great detail on the CDC web page. I highly suggest you take this seriously, and don't try to identify individuals within this data set. _Even yourself_. Really.

http://www.cdc.gov/nchs/data_access/vitalstatsonline.htm 
