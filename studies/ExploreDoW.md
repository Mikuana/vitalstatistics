# Day of Week Exploration
[Back to Study Directory](README.md)

# Summary

This document shows that births tend to occur much more frequently on weekdays, and in the middle of the week in particular. This effect was less prevalent in the 70's, but has become more pronounced over time.

# Analysis




```r
library(vitalstatistics)
library(ggplot2)
library(dplyr)
library(lubridate)
```


```r
b.dow = births  # using a shorthand name for modified data set
```

One of the attributes that we have a nearly complete record for is day of the week. We'll start our analysis by comparing the distribution of live births throughout the week using the complete data set. A check for completeness of the data show that of the 179,279,500 records of live birth in our data set, we have 3,509,300 missing values for the `birth_weekday_date` that are missing data for day of week. We'll look at a breakdown of years where these values are missing (using the `birth_month_date`, which should be 100% complete).


```r
b.dow %>%  
    group_by(birth_year = year(birth_month_date)) %>%
    summarize(
        misses = sum(ifelse(is.na(birth_weekday_date), cases, 0)),
        cases = sum(cases),
        rate = misses / cases,
        rate_format = scales::percent(round(rate, digits=5))
    ) %>%
    filter(misses > 0) %>%
    select(
        `Birth Year` = birth_year,
        `Live Births` = cases,
        `Records Missing Day of Week` = misses,
        `Percent Missing` = rate_format
    ) %>%
    knitr::kable(., format="markdown", align = "r")
```



| Birth Year| Live Births| Records Missing Day of Week| Percent Missing|
|----------:|-----------:|---------------------------:|---------------:|
|       1968|     3501400|                     3501400|            100%|
|       1969|     3600200|                        2200|          0.061%|
|       1970|     3737800|                        3600|          0.096%|
|       1971|     3563400|                         600|          0.017%|
|       1972|     3260500|                         200|          0.006%|
|       1973|     3139700|                         400|          0.013%|
|       1974|     3190500|                         200|          0.006%|
|       1975|     3159600|                         100|          0.003%|
|       1976|     3180000|                         200|          0.006%|
|       1982|     3688700|                         400|          0.011%|

We can see that 1968 is completely lacking day of week data, which is expected since birth records from that year included neither day of month or day of week data. However, after 1968 there is less than 1/10th of a percent of records missing from any year, with the worst years being 1969 and 1970, and missing data halting entirely after 1982. Overall, this is very complete data if we note that 1968 is missing in its entirety.

## Exploration

We start our exploratory analysis by preparing a copy of the data set with attributes that we will need later.


```r
b.dow = b.dow %>%
    filter(!is.na(birth_weekday_date)) %>%  # remove missing records
    ext_birth_weekday %>%
    ext_birth_year %>% 
    ext_birth_decade %>%
    # label 60's as 1969 since that is the only year that's included for this analysis
    mutate(birth_decade = recode(birth_decade, '1960s' = '1969')) %>%
    group_by(birth_weekday)  # add a default grouping for weekday for convenience
```

Then we start our investigation by looking at the relative distribution of births over days of the week.


```r
dow.plot = function(dat) {  # create ggplot function for multiple use
    ggplot(dat, aes(birth_weekday, weekly_share, label=scales::percent(weekly_share))) +
        geom_hline(yintercept = 1/7, col="red") +  # draw a line at 14.3%
        geom_bar(stat="identity", alpha=0.80) +
        geom_label() +
        scale_y_continuous(labels=scales::percent) +
        coord_cartesian(ylim=c(0.07, 0.18)) +
        xlab("Birth Day of Week") +
        ylab("Distribution of Births in Week (%)")
}

b.dow %>%
    summarise(live_births = sum(cases)) %>%
    mutate(weekly_share = live_births / sum(live_births)) %>%
    dow.plot(.) + geom_label(aes(1, 1/7, label=scales::percent(1/7)))
```

![](ExploreDoW_files/figure-html/unnamed-chunk-1-1.png)<!-- -->

Our graph includes a line at 14.3%, which is where the weekly share of births would fall for each day if there was no bias toward any particular day. However, the graph reveals that births are not evenly distributed, with births much more heavily weighted towards weekdays than weekends. Sunday in particular falls well below the 14.3% non-bias level. 

To dive a little deeper into this question while still remaining at the "exploratory" level of analysis, we look at how this distribution has changed over time. We will recast this graphic with a facet for each weekday, track the decade on the y-axis, and plot our outcomes as a line instead of a bar. This will allow us to much more easily discern how frequently births occur on certain days over time. Again, we include a red line to indicate the point which each day would fall if there were no bias towards particular days of the week for birth.


```r
b.dow.decades = b.dow %>%
    group_by(birth_decade, add=TRUE) %>%
    summarise(live_births = sum(cases)) %>%
    group_by(birth_decade) %>%  # group again on summarized data for denominator calculation
    mutate(weekly_share = live_births / sum(live_births))

b.dow.decades %>%
    ggplot(aes(birth_decade, weekly_share, group=birth_weekday)) + 
        facet_grid(. ~ birth_weekday) +
        geom_hline(yintercept = 1/7, col="red") +
        geom_line(stat='identity') +
        scale_y_continuous(labels=scales::percent)+
        coord_cartesian(ylim=c(0.07, 0.18)) +
        theme(axis.text.x=element_text(angle=90, size=8)) +
        xlab("Decade of Birth") +
        ylab("Distribution of Births in Week (%)")
```

![](ExploreDoW_files/figure-html/unnamed-chunk-2-1.png)<!-- -->

With this final graphic, it becomes extremely clear that (1) births are much more heavily biased towards weekdays, (2) births are biased towards the middle of the week in particular, and (3) this trend has become more extreme over time. 

But what does this mean in plain language? We'll propose a theoretical week in which 7000 births occurr. If there was no bias on which day they were born and births occurred completely randomly, then ~1000 births would occur on each day. However, as of the 2010s, the week would probably look like this:


```r
b.dow.decades %>%
    filter(birth_decade == '2010s') %>%
    mutate(est = round(weekly_share / (1/7) * 1000, 0)) %>%
    group_by %>%  # drop decades grouping
    select(
        Weekday = birth_weekday,
        `Estimated Births` = est
    ) %>%
    knitr::kable(., format="markdown", align = "r")
```



| Weekday| Estimated Births|
|-------:|----------------:|
|     Sun|              656|
|     Mon|             1068|
|    Tues|             1162|
|     Wed|             1134|
|   Thurs|             1130|
|     Fri|             1107|
|     Sat|              743|

If historical trends hold, the bias of midweek births will continue to increase and fewer births will occur on the weekend.

[Back to Study Directory](README.md)
