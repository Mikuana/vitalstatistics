'This script "stitches" together the various years of data that are mapped by the
 data dictionary, and reduces records across dimensions as much as possible without
 loss of information.'

library(dplyr)
library(data.table)

# Call up config file attributes and cast them for R
config = ini::read.ini(file.path('data-raw', 'config.ini'))
config$SAMPLING$enabled = config$SAMPLING$enabled == "True"
config$SAMPLING$percentage = as.numeric(config$SAMPLING$percentage)


staged_data = function(year, column_selection=NA) {
    data_folder = file.path('data-raw', 'data')
    if(is.na(column_selection)) { column_selection=TRUE }
    set_dict = data_dictionary()[[as.character(year)]][column_selection]

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
        coded_data[,DOB_YY:=as.integer(year)]
    }

    filter_residents = function(coded_data) {
        coded_data[!RESTATUS == 'Foreign residents']
    }

    # Assemble a command to return the decompressed gz staging file
    gz_com = paste('zcat', file.path(data_folder, paste0('births', year ,'.csv.gz')))

    sel = set_dict %>% names
    col = setNames(set_dict[sel] %>%  sapply(function(x) x[['type']]) %>% as.character, sel)

    fread(input=gz_com, stringsAsFactors=FALSE, select = sel, colClasses = col) %>%
        recode_na %>%
        recode_ordered %>%
        recode_flags %>%
        as.data.table(.) %>%
        add_year %>%
        filter_residents
}



if(config$SAMPLING$enabled) {
    births = mutate(births, cases = cases / config$SAMPLING$percentage)
}

devtools::use_data(births, overwrite=TRUE)
