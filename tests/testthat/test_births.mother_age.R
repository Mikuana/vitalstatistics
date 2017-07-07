context("DQ mother_age")

test_that("field is an integer type", {
  expect_is(births[,mother_age], "integer")
})

test_that("less than 0.2% data missing (after 2002)", {
  nas = births[,.(y = lubridate::year(birth_month_date), mis = is.na(mother_age), cases)][,
    .(num = sum(cases * mis), den = sum(cases)), by=.(y)
  ][, .(y, rate = num / den)]

  for(i in nas[,y]){
    t = ifelse(i > 2002, 2e-3, 0)
    expect_lte(nas[y==i, rate], t, paste(i, "missing", scales::percent(nas[y==i, rate])))
  }
})
