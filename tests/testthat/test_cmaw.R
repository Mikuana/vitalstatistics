context("cmaw")

test_that("known leap years return expected value", {
  expect_equal(cmaw( lubridate::ymd(20120201)), (1/12) / (29 / 366) )
  expect_equal(cmaw( lubridate::ymd(20100101)), (1/12) / (31 / 365) )
})

test_that("date catcher accepts and rejects as expected", {
    expect_error(cmaw_date_catch(1))  # an integer
    expect_error(cmaw_date_catch('x'))  # this is an x
    expect_error(cmaw_date_catch('2016-02-01'))  # looks like a date, but not a lubridate
    expect_null(cmaw_date_catch(lubridate::ymd(20160201)))  # good date
    expect_error(cmaw_date_catch(NA))
})
