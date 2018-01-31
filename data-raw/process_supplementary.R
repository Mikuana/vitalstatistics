library(dplyr)

CDC_cesarean_2013 =
    file.path('data', 'CDC_cesarean_2013.txt') %>%
    read.table(header=TRUE, sep="|", skip=5) %>%
    mutate(
        TotalCesareanRate = TotalCesareanRate / 100,
        LowRiskCesareanRate = LowRiskCesareanRate / 100
    )

HHS_cesarean_1989 =
    file.path('data', 'HHS_cesarean_1989.txt') %>%
    read.table(header=TRUE, sep="|", skip=5) %>%
    mutate_at(vars(AllAges:AgesOver34), funs( . / 100 ))

HHS_cesarean_1996 =
    file.path('data', 'HHS_cesarean_1996.txt') %>%
    read.table(header=TRUE, sep="|", skip=5) %>%
    mutate_at(vars(AllAges:AgesOver34), funs( . / 100 ))

devtools::use_data(CDC_cesarean_2013, overwrite=TRUE)
devtools::use_data(HHS_cesarean_1989, overwrite=TRUE)
devtools::use_data(HHS_cesarean_1996, overwrite=TRUE)
