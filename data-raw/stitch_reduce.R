'This script "stitches" together the various years of data that are mapped by the
 data dictionary, and reduces records across dimensions as much as possible without
 loss of information.'

library(dplyr)

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
        mutate(coded_data, DOB_YY=as.integer(set_year))

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
    cesarean_logical = function(labeled_data) {
        'Indicate whether the case resolved with a cesarean section using a logical,
         with unknown cases denoted by an NA'
        if(all(c('UME_PRIMC', 'UME_REPEC') %in% names(labeled_data))) {
            mutate(labeled_data,
                cesarean_lg = 
                    ifelse(UME_PRIMC == 'Yes' | UME_REPEC == 'Yes', TRUE,
                    ifelse(UME_PRIMC == 'No' & UME_REPEC == 'No', FALSE,
                        NA))
                       
            )
        } else {mutate(labeled_data, cesarean_lg = NA)}
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
        recode_na %>%
        recode_ordered %>%
        recode_flags %>%
        filter_residents %>%
        # resident_record_test %>%
        add_year %>%
        cesarean_logical %>%
        remap_BFACIL
}


#===============================================================================
# RECORD REDUCTION
# reduce the number of physical records by grouping and counting by a data set
# with minimal dimensions.
#===============================================================================
births = lapply(data_dictionary()$years(), function(y) {
    staged_data(y) %>%
        group_by(
            DOB_YY,
            DOB_MM,
            BFACIL3,
            cesarean_lg
        ) %>%
        summarize(cases = n())
}) %>% data.table::rbindlist(use.names=TRUE)


if(config$SAMPLING$enabled) {
    births = mutate(births, cases = cases / config$SAMPLING$percentage)
}

devtools::use_data(births, overwrite=TRUE)
