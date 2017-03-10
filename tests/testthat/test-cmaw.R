context("cmaw")

test_that("known leap years return expected value", {
  expect_equal(cmaw( lubridate::ymd(20120201)), (1/12) / (29 / 366) )
  expect_equal(cmaw( lubridate::ymd(20100101)), (1/12) / (31 / 365) )
})
