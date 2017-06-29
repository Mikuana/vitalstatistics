context("DQ birth_in_hospital")

test_that("field is a logical type", {
  expect_is(births[,birth_in_hospital], "logical")
})

test_that("", {
  births[,sum(cases),by=.(birth_in_hospital, y=lubridate::year(birth_month_date))] %>% print.AsIs
})
