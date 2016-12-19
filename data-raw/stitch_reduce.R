'This script "stitches" together the various years of data that are mapped by the
 data dictionary, and reduces records across dimensions as much as possible without
 loss of information.'

library(dplyr)
source(file.path('R', 'loaders.R'))

# Call up config file attributes and cast them for R
config = ini::read.ini(file.path('data-raw', 'config.ini'))
config$SAMPLING$enabled = config$SAMPLING$enabled == "True"
config$SAMPLING$percentage = as.numeric(config$SAMPLING$percentage)


staged_data = function(set_year, column_selection=NA) {
    data_folder = file.path('data-raw', 'data')
    if(is.na(column_selection)) { column_selection=TRUE }
    dict = data_dictionary()
    set_dict = dict[[as.character(set_year)]][column_selection]

    #===============================================================================
    # Data Dictionary Labelling and Transformations
    #===============================================================================
    recode_ordered = function(coded_data) {
        'Read definitions from data from dictionary and apply it to dataset, and
         construct ordered factor mutate statements as strings.
        '
        fms = list()
        for(i in names(set_dict)) {
            if(all(c('levels', 'labels') %in% names(set_dict[[i]]))) {
                levels = set_dict[[i]]$levels
                if(is.numeric(levels)) {
                    levels = paste0(set_dict[[i]]$levels, collapse=",")
                }else{
                    levels = paste0('"', set_dict[[i]]$levels, '"', collapse=",")
                }
                labels = paste0('"', set_dict[[i]]$labels, '"' , collapse=",")
                fms[[i]] = paste0("ordered(",i,", levels=c(",levels,"), labels=c(",labels,"))")
            }
        }
        return(mutate_(coded_data, .dots = fms))
    }

    recode_flags = function(coded_data) {
        lg_fields = NULL
        for(x in names(set_dict)) {
            if(set_dict[[x]][['type']]=='logical') {
                lg_fields = c(lg_fields, x)
            }
        }
        lg_mutate = function(x) { as.logical(ifelse(is.na(x), 0, x)) }
        if(is.null(lg_fields)) { return(coded_data) }
        else { return( coded_data %>% mutate_each_(funs(lg_mutate(.)), lg_fields) )}
    }

    recode_na = function(coded_data) {
        na_formulas = list()
        for(x in names(set_dict)) {
            if('na_value' %in% names(set_dict[[x]])) {
                row = set_dict[[x]]
                na_formulas[x] = paste0("ifelse(", x," == ", row$na_value,", NA,", x, ")")
            }
        }
        return(mutate_(coded_data, .dots = na_formulas))
    }

    add_year = function(coded_data) {
        mutate(coded_data, birth_year=as.integer(set_year))

    }

    #===============================================================================
    # Data set filtering
    #===============================================================================
    filter_residents = function(coded_data) {
        filter(coded_data, !RESTATUS == 'Foreign residents')
    }

    #===============================================================================
    # Transformations
    #===============================================================================
    record_weighting = function(coded_data) {
        'Prior to 1985, much of the birth weight records represented 50% samples. For
         our purposes this requires duplication of any record with a RECWT value
         equal to 2. Prior to 1972, the the RECWT field did not exist, but all records
         were 50%, so we impute the values'
         if(set_year %in% 1968:1971) {
            coded_data = mutate(coded_data, RECWT = 2)
         }

         if('RECWT' %in% names(coded_data)) {
                list(
                    coded_data,
                    filter(coded_data, RECWT == 2)
                ) %>%
                data.table::rbindlist(use.names=TRUE)
         }
         else {return(coded_data)}
    }

    add_month_date = function(coded_data) {
        'Convert birth_year and birth_month fields into pseudo-date, using the first day of
         month for each combination. This simplifies the use of plotting with many
         other tools and functions in R.'
         mutate(coded_data, pseudo_birth_date = lubridate::ymd(paste(birth_year, DOB_MM, 1, sep='_')))
    }


    add_cesarean_logical = function(labeled_data) {
        'Indicate whether the case resolved with a cesarean section using a logical,
         with unknown cases denoted by an NA. There is a specific strategy to which fields
         are used to determine if there was a cesarean section

          1. check the UME cesarean fields which are present much earlier on birth records
          2. then check the ME_ROUT field which was introduced in 2004
          3. then check the DMETH_REC field

         There are a number of years where both 1 and 2 are present in birth records,
         so we use a coalesce function in attempt to combine results. In years where
         ME_ROUT is present, available values are proritized by this field. However,
         if the field is NA or otherwise unknown, then the function falls back to
         whatever value has already been set in the field. In many cases this will
         include the logical interpretation of the UME fields.'
        # Start by creating the cesarean_lg field to prevent errors in mutate coalesce
        labeled_data = mutate(labeled_data, cesarean = NA)

        if(all(c('UME_PRIMC', 'UME_REPEC') %in% names(labeled_data))) {
            labeled_data = mutate(labeled_data,
                cesarean =
                    coalesce(cesarean,
                        ifelse(UME_PRIMC == 'Yes' | UME_REPEC == 'Yes', TRUE,
                        ifelse(UME_PRIMC == 'No' & UME_REPEC == 'No', FALSE,
                            NA))
                    )
            )
        }

        if('ME_ROUT' %in% names(labeled_data)) {
            labeled_data = mutate(labeled_data,
                cesarean =
                    coalesce(cesarean,
                        ifelse(ME_ROUT == 'Cesarean', TRUE,
                        ifelse(ME_ROUT != 'Unknown or not stated', FALSE,
                            NA))
                    )
            )
        }

        if('DMETH_REC' %in% names(labeled_data)) {
            labeled_data = mutate(labeled_data,
                cesarean =
                    coalesce(cesarean,
                        ifelse(DMETH_REC == 'Cesarean', TRUE,
                        ifelse(DMETH_REC == 'Vaginal', FALSE,
                            NA))
                    )
            )
        }

        return(labeled_data)
    }

    remap_BFACIL = function(labeled_data) {
        'Remap pre-1989 place of birth records to conform with the BFACIL3 field'
        fields = names(labeled_data)
        if(!'BFACIL3' %in% fields){
            if('PODEL' %in% fields) {
                return(mutate(labeled_data,
                    BFACIL3 =
                        ifelse(PODEL == 'Hospital Births', 'In Hospital',
                        ifelse(PODEL %in%
                            c('Nonhospital Births', 'En route or born on arrival (BOA)'),
                            'Not in Hospital', 'Unknown or Not Stated')
                        )
                ))
            }
            else{return(mutate(labeled_data, BFACIL3 = 'Unknown or Not Stated'))}
        }
        else {return(labeled_data)}
    }

    add_hospital_logical = function(labeled_data) {
        'Convert place of birth field into a logical indicating whether the birth
         occured in a hospital'
        mutate(labeled_data,
                birth_in_hospital = ifelse(BFACIL3=='In Hospital', TRUE,
                                    ifelse(BFACIL3=='Not in Hospital', FALSE,
                                        NA))
            )
    }

    remap_STATENAT = function(labeled_data) {
        'Recode underlying levels of the OSTATE and STATENAT fields so that they
         match one another. This is necessary because the OSTATE field uses two
         character representations instead of integers.
        '
        fields = names(labeled_data)
        if(!'STATENAT' %in% fields) {
            if('OSTATE' %in% fields) {
                # Use 2002 STATENAT definitions to remap OSTATE codes
                lkp = setNames(
                        data_dictionary()$`2002`$STATENAT$levels,
                        data_dictionary()$`2002`$STATENAT$labels
                    )
                mutate(labeled_data,
                    STATENAT = factor(lkp[as.character(OSTATE)], lkp, names(lkp))
                )
            }
            else {
                return( mutate(labeled_data, STATENAT = NA) )
            }
        }
        else{ return(labeled_data) }
    }

    #===============================================================================
    # Column Renaming
    #===============================================================================
    field_renames = function(coded_data) {
        rename(coded_data,
                birth_month = DOB_MM,
                birth_state = STATENAT
            )
    }

    #===============================================================================
    # Record Tests
    #===============================================================================
    raw_record_test = function(coded_data) {
        'Check the number of records against those listed by the CDC vital statistics
         data dictionaries.'
        expec = dict$checks[[as.character(set_year)]]$all_records

        if(is.null(expec)) {
            return(coded_data)
        }

        if(config$SAMPLING$enabled) {
            expec = as.integer(expec * config$SAMPLING$percentage)
        }

        testthat::expect_equal(nrow(coded_data), expec, tolerance = 0, scale=1,
            info=paste("Missing raw records from data set", as.character(set_year))
        )

        return(coded_data)
    }

    resident_record_test = function(labeled_data) {
        'Check the number of records of resident births against those listed by
         the CDC vital statistics data dictionaries.'
        expec = dict$checks[[as.character(set_year)]]$resident_records

        if(is.null(expec)) {
            return(labeled_data)
        }

        testthat::expect_equal(nrow(coded_data), expec,
            info=paste("Missing resident records from data set", as.character(set_year)),
            tolerance = 100, scale=1
        )
        return(labeled_data)
    }

    #===============================================================================
    # Function Execution
    #===============================================================================

    # Assemble a command to return the decompressed gz staging file
    gz_com = paste('zcat', file.path(data_folder, paste0('births', set_year ,'.csv.gz')))

    sel = set_dict %>% names
    col = setNames(set_dict[sel] %>%  sapply(function(x) x[['type']]) %>% as.character, sel)

    data.table::fread(input=gz_com, stringsAsFactors=FALSE, select = sel, colClasses = col) %>%
        raw_record_test %>%
        record_weighting %>%
        recode_na %>%
        recode_ordered %>%
        recode_flags %>%
        filter_residents %>%
        # resident_record_test %>%
        add_year %>%
        add_month_date %>%
        add_cesarean_logical %>%
        remap_BFACIL %>%
        add_hospital_logical %>%
        remap_STATENAT %>%
        field_renames
}


#===============================================================================
# RECORD REDUCTION
# reduce the number of physical records by grouping and counting by a data set
# with minimal dimensions.
#===============================================================================
births = lapply(data_dictionary()$years(), function(y) {
    staged_data(y) %>%
        group_by(
            pseudo_birth_date,
            birth_year,
            birth_month,
            birth_state,
            birth_in_hospital,
            cesarean
        ) %>%
        summarize(cases = n())
}) %>% 
    data.table::rbindlist(use.names=TRUE) %>%
    mutate(birth_year=ordered(birth_year))


if(config$SAMPLING$enabled) {
    births = mutate(births, cases = cases / config$SAMPLING$percentage)
}

devtools::use_data(births, overwrite=TRUE)
