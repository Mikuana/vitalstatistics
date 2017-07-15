context("DQ birth_via_cesarean")

test_that("field is a logical type", {
  expect_is(births[,birth_via_cesarean], "logical")
})

test_that("non-NA values exist in each year after 1988", {
  exp = as.numeric(1989:2015)
  rep = births[!is.na(birth_via_cesarean),.N,by=.(y=lubridate::year(birth_month_date))][,y]
  expect_identical(exp, rep)
})
