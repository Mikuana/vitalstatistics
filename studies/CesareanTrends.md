# Historical Cesarean Section Trends
[Back to Document Directory](README.md)




```r
library(ggplot2)
library(dplyr)
library(vitalstatistics)
```

The graphic below shows several different rate calculations for cesarean section. The red dotted lines are provided by various reports on cesarean rates, while the black line is the result of aggregating birth records. The bars show the percentage of cases that contain a logical result for cesarean section, scaled down to 10%.


```r
cs_group = function(x = births) {
    x %>% group_by(time = DOB_YY) %>%
        summarize(
            cesarean_rate = rate_lg(cesarean_lg, cases)(),
            coverage = sum( ifelse(is.na(cesarean_lg), 0, cases) ) / sum(cases)
        )
}

cs = cs_group()
cs_OR = cs_group(filter(births, STATENAT == 'Oregon'))

ggplot(cs, aes(time, cesarean_rate)) +
    geom_line(stat="identity") +
    scale_y_continuous(label=scales::percent) +
    geom_line(data=cs_OR, aes(time, cesarean_rate), stat="identity", color="blue") +
    geom_line(data=CDC_cesarean_2013, aes(Year, TotalCesareanRate),
                stat="identity", color="red", linetype=2, size=0.5, alpha=0.5) +
    geom_line(data=HHS_cesarean_1989, aes(Year, AllAges),
                stat="identity", color="red", linetype=2, size=0.5, alpha=0.5) +
    geom_line(data=HHS_cesarean_1996, aes(Year, AllAges),
                stat="identity", color="red", linetype=2, size=0.5, alpha=0.5) +
    geom_bar(aes(time, coverage / 10), stat="identity", alpha=0.5) +
    scale_shape_identity()
```

```
## Warning: Removed 21 rows containing missing values (geom_path).

## Warning: Removed 21 rows containing missing values (geom_path).
```

![](CesareanTrends_files/figure-html/unnamed-chunk-1-1.png)<!-- -->

We can see that we have fairly complete logical results for cesarean section starting in 1989, but that things got very squirly in 2008.
