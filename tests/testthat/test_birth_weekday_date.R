context("DQ birth_weekday_date")

test_that("column is a Date type", {
  expect_is(births[, birth_weekday_date], "Date")
})

test_that("less than 0.1% data missing (after 1968)", {
  nas = births[,.(y = lubridate::year(birth_month_date), mis = is.na(birth_weekday_date), cases)][,
    .(num = sum(cases * mis), den = sum(cases)), by=.(y)
  ][y > 1968, .(y, rate = num / den)]

  for(i in nas[,y]){
    expect_lt(nas[y==i, rate], 1e-3, paste(i, "missing", scales::percent(nas[y==i, rate])))
  }
})

test_that("year and month dateparts match birth_month_date, when not NA", {
  expect_true(all(births[
      !is.na(birth_weekday_date),
      lubridate::year(birth_month_date) == lubridate::year(birth_weekday_date)
  ]), "Mismatched year between birth_weekday_date and birth_month_date")

  expect_true(all(births[
    !is.na(birth_weekday_date),
    lubridate::month(birth_month_date) == lubridate::month(birth_weekday_date)
    ]), "Mismatched month between birth_weekday_date and birth_month_date")
})

test_that("Exactly 7 days represented in each month", {
  expect_true(label="Exactly 7 days represented in a month", all(
    births[!is.na(birth_weekday_date),.(
      y = lubridate::year(birth_weekday_date),
      m = lubridate::month(birth_weekday_date),
      d = lubridate::day(birth_weekday_date)
    )][,
      .N, by=.(y,m,d)
    ][,
      .N, by=.(y,m)
    ][,N==7]
  ))
})

test_that("records exist for every month in expected time frame", {
  # no weekday dates in 1968, so we start in 1969 instead
  expected_dates = seq.Date(lubridate::ymd(19690101), lubridate::ymd(20151231), by='month')
  represented_dates = births[!is.na(birth_weekday_date),
         .(u=unique(birth_weekday_date))][,
            .(x = lubridate::ymd(paste(
              lubridate::year(u),
              lubridate::month(u),
              '01'
            ))
            )
        ][, sort(unique(x))]

  comparison = all.equal(expected_dates, represented_dates)
  expect_true(comparison, comparison)
})
