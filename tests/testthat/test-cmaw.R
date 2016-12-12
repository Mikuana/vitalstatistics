library(vitalstatistics)
context("Expected Values")

test_that("specified dates meet expected values", {
  expect_equal(cmaw( lubridate::ymd(20120201)), (1/12) / (29 / 366) ),
  expect_equal(cmaw( lubridate::ymd(20100101)), (1/12) / (31 / 365) )
})
