context("DQ birth_state")

test_that("51 states are represented in each expected year", {
  expect_true(all(
    births[,.(y=lubridate::year(birth_month_date), birth_state)
    ][y %in% 1968:2004,.N,by=.(birth_state, y)
    ][, .N, by=y][,N == 51]
  ))
})

test_that("there are no missing values in expected years", {
  expect_equal(births[is.na(birth_state) & lubridate::year(birth_month_date) %in% 1968:2004, .N], 0)
})

test_that("no states are represented after 2004", {
  expect_true(all(births[lubridate::year(birth_month_date) > 2004, is.na(birth_state)]))
})

test_that("territories have no records", {
  expect_equal(births[birth_state=="Puerto Rico",.N], 0)
  expect_equal(births[birth_state=="Virgin Islands",.N], 0)
  expect_equal(births[birth_state=="Guam",.N], 0)
})
