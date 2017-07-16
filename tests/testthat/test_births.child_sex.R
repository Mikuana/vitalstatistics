context("DQ child_sex")

test_that("column is a factor type", {
  expect_is(births[, child_sex], "factor")
})

test_that("no missing data in field", {
  expect_equal(nrow(births[is.na(child_sex)]), 0)
})
