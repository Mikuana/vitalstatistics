# Test that the births data object has values for each month in between the minimum
# and maximum month_date values included in the data set
(function(x = births$month_date) {
    expected = seq(min(x), max(x), by='month')
    missing = !expected %in% x
    
    testthat::expect_false(
        any(missing),
        sprintf(
            'The births data is missing values for the following months:\n%s',
            paste(expected[missing], collapse=", ")
        )
    )
})()
