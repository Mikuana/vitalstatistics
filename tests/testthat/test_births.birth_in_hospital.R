context("DQ birth_in_hospital")

test_that("field is a logical type", {
  expect_is(births[,birth_in_hospital], "logical")
})

test_that("non-NA values exist in each expected year", {
  exp = as.numeric(1968:2015)
  rep = births[!is.na(birth_in_hospital),.N,by=.(y=lubridate::year(birth_month_date))][,y]
  expect_identical(exp, rep)
})
