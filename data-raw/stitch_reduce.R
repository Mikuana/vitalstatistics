'This script "stitches" together the various years of data that are mapped by the
 data dictionary, and reduces records across dimensions as much as possible without
 loss of information.'

library(dplyr)
library(data.table)
library(lubridate)

# call data dictionary function from this package. That means you need to build and load this
# package before you can process the raw data
dictionary = data_dictionary()


staged_data = function(dictionary, year, column_selection=NA) {
    data_folder = file.path('data-raw', 'data')
    if(is.na(column_selection)) { column_selection=TRUE }
    dictionary = data_dictionary()
    ydict = dictionary[[as.character(year)]][column_selection]

    recode_ordered = function(coded_data) {
        'Read definitions from data from dictionary and apply it to dataset, and
         construct ordered factor mutate statements as strings.
        '
        fms = list()
        for(i in names(ydict)) {
            if(all(c('levels', 'labels') %in% names(ydict[[i]]))) {
                levels = ydict[[i]]$levels
                if(is.numeric(levels)) {
                    levels = paste0(ydict[[i]]$levels, collapse=",")
                }else{
                    levels = paste0('"', ydict[[i]]$levels, '"', collapse=",")
                }
                labels = paste0('"', ydict[[i]]$labels, '"' , collapse=",")
                fms[[i]] = paste0("ordered(",i,", levels=c(",levels,"), labels=c(",labels,"))")
            }
        }
        return(mutate_(coded_data, .dots = fms))
    }

    recode_flags = function(coded_data) {
        lg_fields = NULL
        for(x in names(ydict)) {
            if(ydict[[x]][['type']]=='logical') {
                lg_fields = c(lg_fields, x)
            }
        }
        lg_mutate = function(x) { as.logical(ifelse(is.na(x), 0, x)) }
        if(is.null(lg_fields)) { return(coded_data) }
        else { return( coded_data %>% mutate_each_(funs(lg_mutate(.)), lg_fields) )}
    }

    recode_na = function(coded_data) {
        na_formulas = list()
        for(x in names(ydict)) {
            if('na_value' %in% names(ydict[[x]])) {
                row = ydict[[x]]
                na_formulas[x] = paste0("ifelse(", x," == ", row$na_value,", NA,", x, ")")
            }
        }
        return(mutate_(coded_data, .dots = na_formulas))
    }

    add_year = function(coded_data) { mutate(coded_data, DOB_YY = as.integer(year))}

    # Assemble a command to return the decompressed gz staging file
    gz_com = paste('zcat', file.path(data_folder, paste0('births', year ,'.csv.gz')))

    sel = ydict %>% names
    col = setNames(ydict[sel] %>%  sapply(function(x) x[['type']]) %>% as.character, sel)

    fread(input=gz_com, stringsAsFactors=FALSE, select = sel, colClasses = col) %>%
        recode_na() %>%
        recode_ordered() %>%
        recode_flags() %>%
        add_year
}


chunk0 =
    lapply(1968:1988, function(x) {
        staged_data(dictionary, x) %>%
            group_by(DOB_YY, DOB_MM) %>%
            summarize(cases = n())
    }) %>% rbindlist(use.names=TRUE, fill=TRUE)

chunk1 =
    lapply(1989:2003, function(x) {
        staged_data(dictionary, x) %>%
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

chunk2 =  # this section is loading two years where characters dont match the dictionary
    lapply(2004:2008, function(x) {
        staged_data(dictionary, x) %>%
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


chunk3 =  # TODO: figure out why fields are missing for 2010
    lapply(2009:2010, function(x) {
        staged_data(dictionary, x) %>%
            mutate(
                ME_ROUT_x =
                    ifelse(UME_PRIMC == 'Yes' | UME_REPEC == 'Yes', 'Cesarean',
                    ifelse(UME_FORCP == 'Yes', 'Forceps',
                    ifelse(UME_VAC == 'Yes', 'Vacuum',
                    ifelse(UME_VAG == 'Yes' | UME_VBAC == 'Yes', 'Spontaneous',
                    'Unknown or not stated')))
                    )
                ,

                ME_ROUT = 
                    coalesce(
                        ifelse(
                            ME_ROUT == 'Unknown or not stated', NA, as.character(ME_ROUT)
                        ),
                        as.character(ME_ROUT_x),
                        'Unknown or not stated'
                    )
                ,
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

births = rbindlist( list(chunk0, chunk1, chunk2, chunk3),use.names=TRUE, fill=TRUE)

births = mutate(births,month_date = ymd(paste(DOB_YY, DOB_MM, '01', sep='_')))

devtools::use_data(births, overwrite=TRUE)
