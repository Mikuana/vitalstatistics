"Performs a mapping of values between birth year data sets, which are distinct enough
 that they cannot be reduced within the dictionary, but equivalent enough that we
 can reduce them in this dictionary.
"

dictionary = data_dictionary()

chunk0 =
    lapply(1968:1988, function(x) {
        load_data(dictionary, x) %>%
            group_by(DOB_YY, DOB_MM) %>%
            summarize(cases = n())
    }) %>% rbindlist(use.names=TRUE, fill=TRUE)

chunk1 =
    lapply(1989:2003, function(x) {
        load_data(dictionary, x) %>%
            mutate(
                ME_ROUT = ordered(
                    ifelse(UME_PRIMC == 'Yes' | UME_REPEC == 'Yes', 'Cesarean',
                           ifelse(UME_FORCP == 'Yes', 'Forceps',
                                  ifelse(UME_VAC == 'Yes', 'Vacuum',
                                         ifelse(UME_VAG == 'Yes' | UME_VBAC == 'Yes', 'Spontaneous',
                                                'Unknown or not stated')))),
                    levels = dictionary[['default']][['ME_ROUT']][['labels']]
                ),

                RF_CESAR = ordered(
                    ifelse(UME_VAG == 'Yes' | UME_PRIMC == 'Yes', 'No',
                           ifelse(UME_VBAC == 'Yes' | UME_REPEC == 'Yes', 'Yes',
                                  'Unknown or not stated')),
                    levels = dictionary[['default']][['RF_CESAR']][['labels']]
                )
            ) %>%
            group_by(DOB_YY, DOB_MM, BFACIL3, ME_ROUT, RF_CESAR) %>%
            summarize(cases = n())
    }) %>% rbindlist(use.names=TRUE, fill=TRUE)

chunk2 =
    lapply(2004:2008, function(x) {
        load_data(dictionary, x) %>%
            mutate(
                ME_ROUT_x =
                    ifelse(UME_PRIMC == 'Yes' | UME_REPEC == 'Yes', 'Cesarean',
                           ifelse(UME_FORCP == 'Yes', 'Forceps',
                                  ifelse(UME_VAC == 'Yes', 'Vacuum',
                                         ifelse(UME_VAG == 'Yes' | UME_VBAC == 'Yes', 'Spontaneous',
                                                'Unknown or not stated')))
                    ),

                ME_ROUT = coalesce(
                        ifelse(ME_ROUT == 'Unknown or not stated', NA, as.character(ME_ROUT)),
                        ME_ROUT_x,
                        'Unknown or not stated'
                    ),
                ME_ROUT = ordered(ME_ROUT,
                                  levels = dictionary[['default']][['ME_ROUT']][['labels']]
                    ),

                RF_CESAR = ordered(
                    ifelse(UME_VAG == 'Yes' | UME_PRIMC == 'Yes', 'No',
                           ifelse(UME_VBAC == 'Yes' | UME_REPEC == 'Yes', 'Yes',
                                  'Unknown or not stated')),
                    levels = dictionary[['default']][['RF_CESAR']][['labels']]
                )
            ) %>%
            group_by(DOB_YY, DOB_MM, BFACIL3, ME_ROUT, RF_CESAR) %>%
            summarize(cases = n())
    }) %>% rbindlist(use.names=TRUE, fill=TRUE)


chunk3 =
    lapply(2009:2014, function(x) {
        load_data(dictionary, x) %>%
            mutate(
                ME_ROUT_x =
                    ifelse(UME_PRIMC == 'Yes' | UME_REPEC == 'Yes', 'Cesarean',
                           ifelse(UME_FORCP == 'Yes', 'Forceps',
                                  ifelse(UME_VAC == 'Yes', 'Vacuum',
                                         ifelse(UME_VAG == 'Yes' | UME_VBAC == 'Yes', 'Spontaneous',
                                                'Unknown or not stated')))
                    ),

                ME_ROUT = coalesce(
                    ifelse(ME_ROUT == 'Unknown or not stated', NA, as.character(ME_ROUT)),
                    ME_ROUT_x,
                    'Unknown or not stated'
                ),
                ME_ROUT = ordered(ME_ROUT,
                                  levels = dictionary[['default']][['ME_ROUT']][['labels']]
                ),

                RF_CESAR = ordered(
                    ifelse(UME_VAG == 'Yes' | UME_PRIMC == 'Yes', 'No',
                           ifelse(UME_VBAC == 'Yes' | UME_REPEC == 'Yes', 'Yes',
                                  'Unknown or not stated')),
                    levels = dictionary[['default']][['RF_CESAR']][['labels']]
                )
            ) %>%
            group_by(DOB_YY, DOB_MM, BFACIL3, ME_ROUT, RF_CESAR) %>%
            summarize(cases = n())
    }) %>% rbindlist(use.names=TRUE, fill=TRUE)

cs_dat = rbindlist(
    list(chunk0, chunk1, chunk2, chunk3),
    use.names=TRUE, fill=TRUE
    )

cs_dat = mutate(cs_dat,
                month_date = ymd(paste(DOB_YY, DOB_MM, '01', sep='_'))
                )

devtools::use_data(cs_dat)
