context("DQ birth_month_date")

test_that("case values are always a positive integer", {
  expect_type(births[,cases], 'integer')
  expect_true(all(births[,cases >= 1]))
})

test_that("case totals match values from data dictionary", {
  expected = c(
    `1968` = NA,
    `1969` = NA,
    `1970` = NA,
    `1971` = NA,
    `1972` = NA,
    `1973` = NA,
    `1974` = NA,
    `1975` = NA,
    `1976` = NA,
    `1977` = NA,
    `1978` = NA,
    `1979` = 3499795,
    `1980` = 3617981,
    `1981` = 3635515,
    `1982` = 3685457,
    `1983` = 3642821,
    `1984` = 3673568,
    `1985` = 3765064,
    `1986` = 3760695,
    `1987` = 3813216,
    `1988` = 3913793,
    `1989` = 4045693,
    `1990` = 4162917,
    `1991` = 4115342,
    `1992` = 4069428,
    `1993` = 4004523,
    `1994` = 3956925,
    `1995` = 3903012,
    `1996` = 3894874,
    `1997` = 3884329,
    `1998` = 3945192,
    `1999` = 3963465,
    `2000` = 4063823,
    `2001` = 4031531,
    `2002` = 4027376,
    `2003` = 4096092,
    `2004` = 4118907,
    `2005` = 4145619,
    `2006` = 4273225,
    `2007` = 4324008,
    `2008` = 4255156,
    `2009` = 4137836,
    `2010` = 4007105,
    `2011` = 3961220,
    `2012` = 3960796,
    `2013` = 3940764,
    `2014` = 3998175,
    `2015` = 3988733
  )
  year_agg = births[,.(cases = sum(cases)), by=.(y=lubridate::year(birth_month_date))]
  represented = setNames(year_agg[,cases], year_agg[,y])
  for(i in names(represented)) {
    expect_true(
      i %in% names(expected),
      paste("case count expectation not set for", i)
    )
    expect_true(
      expected[i] == represented[i] | is.na(expected[i]),
      paste("case totals do not match expectations for", i)
    )
  }
})
