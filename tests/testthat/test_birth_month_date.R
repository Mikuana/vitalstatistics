context("DQ birth_month_date")

test_that("all records are on first of month in expected years", {
  expect_true(all(births[,!is.na(birth_month_date)]))  # no nulls
  expect_true(all(births[,lubridate::day(birth_month_date)] == 1))  # first of month
})

test_that("records exist for every month in expected time frame", {
  expected_dates = seq.Date(lubridate::ymd(19680101), lubridate::ymd(20151231), by='month')
  represented_dates = births[,unique(birth_month_date)]
  comparison = all.equal(expected_dates, represented_dates)
  expect_true(comparison, comparison)
})
