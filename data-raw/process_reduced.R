# This script "stitches" together the various years of data that are mapped by the
# data dictionary, and reduces records across dimensions as much as possible without
# loss of information.

library(dplyr)

data_dictionary = function() {
  get_tree = function() {
    jsonlite::fromJSON(file.path('.', 'dictionary.json'))
  }


  get_nodes = function() {
    nodes = names(get_tree())
    property_node_pattern = '^__\\w+__$'

    # ignore non-field
    list(
      fields = nodes[!grepl(property_node_pattern, nodes)],
      properties = nodes[grepl(property_node_pattern, nodes)]
    )

  }

  tree = get_tree()
  nodes = get_nodes()

  materialize = function() {
    # Materialize full property definitions for each year node by adding in default values if
    # the year doesn't define them already. This also swaps the node order from code (field)
    # coming before year, to year coming before field.
    dict = list()
    for(node in nodes$fields) {
      defs = tree[[node]][['default']]
      subnodes = names(tree[[node]])
      years = subnodes[which(subnodes != 'default')]

      for(year in subnodes) {
        props = tree[[node]][[year]]
        dict[[year]][[node]] = c(props, defs[!names(defs) %in% names(props)])
      }
    }

    dict$years = function() {
      # Returns a vector of years that are included in the data dictionary
      names(tree$`__checks__`)
    }

    dict$checks = tree$`__checks__`

    return(dict)
  }
  materialize()
}


# Call up config file attributes and cast them for R
config = ini::read.ini(file.path('.', 'config.ini'))
config$SAMPLING$enabled = config$SAMPLING$enabled == "True"
config$SAMPLING$percentage = as.numeric(config$SAMPLING$percentage)


staged_data = function(set_year, column_selection=NA) {
  data_folder = file.path('.', 'data')
  if(is.na(column_selection)) { column_selection=TRUE }
  dict = data_dictionary()
  set_dict = dict[[as.character(set_year)]][column_selection]

  #===============================================================================
  # Data Dictionary Labelling and Transformations
  #===============================================================================
  recode_factors = function(coded_data) {
    # Read definitions from data from dictionary and apply it to dataset, and
    # construct ordered factor mutate statements as strings.
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
        cast_type = ifelse(set_dict[[i]]$ordered=='True', 'ordered', 'factor')
        fms[[i]] = paste0(cast_type,"(",i,", levels=c(",levels,"), labels=c(",labels,"))")
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
    # Prior to 1985, much of the birth weight records represented 50% samples. For
    # our purposes this requires duplication of any record with a RECWT value
    # equal to 2. Prior to 1972, the the RECWT field did not exist, but all records
    # were 50%, so we impute the values
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

  add_birth_date = function(coded_data) {
    # Convert birth year, month, and day into a date. This is not retained in
    # the final output, but is necessary in some cases to calculate the birth_weekday_date
    if('DOB_MD' %in% names(coded_data)) {
      mutate(coded_data,
        birth_date =
          lubridate::ymd(paste0(
              birth_year,
              formatC(DOB_MM, width = 2, format = "d", flag = "0"),
              formatC(DOB_MD, width = 2, format = "d", flag = "0")
            )
          )
      )
    } else {
      return( mutate(coded_data, birth_date = as.Date(NA) ))
    }
  }

  add_birth_month_date = function(coded_data) {
    # Add a field which maps the birth date to the first day of the month. Since
    # we always at least know the year and month when a birth occured. By converting
    # this to an actual date value, it makes manipulation of records simpler.
    mutate(coded_data,
      birth_month_date = lubridate::ymd(paste0(birth_year, DOB_MM, '01'))
    )
  }

  add_birth_weekday_date = function(coded_data) {
    # Add a field which maps the year, month, and weekday of the birth to a weekday
    # date. This is similar to the birth_month_date, but instead of fixing all
    # values to the first day of the month, the dates are converted to the corresponding
    # weekday of the first full week in the month.
    coded_data = mutate(coded_data,
      birth_weekday_date = birth_month_date - lubridate::wday(birth_month_date) + 7
    )
    if('DOB_WK' %in% names(coded_data)) {
      mutate(coded_data,
        birth_weekday_date = birth_weekday_date + as.integer(DOB_WK)
      )
    } else {
      mutate(coded_data,
        birth_weekday_date = birth_weekday_date + lubridate::wday(birth_date)
      )
    }
  }

  add_maternal_age_int = function(coded_data) {
    # Age of mother at time of delivery. This function maps single years.
    coded_data = mutate(coded_data,  mother_age_int = as.integer(NA))

    if('DMAGE' %in% names(coded_data)) {
      coded_data = mutate(
        coded_data,
        mother_age_int = coalesce(mother_age_int, DMAGE)
      )
    }

    if('UMAGERPT' %in% names(coded_data)) {
      coded_data = mutate(
        coded_data,
        mother_age_int = coalesce(mother_age_int, UMAGERPT)
      )
    }

    if('MAGER' %in% names(coded_data)) {
      coded_data = mutate(
        coded_data,
        mother_age_int = coalesce(
          mother_age_int, ifelse(MAGER %in% 13:49, MAGER, NA)
        )
      )
    }

    if('MAGER41' %in% names(coded_data)) {
      coded_data = mutate(
        coded_data,
        mother_age_int = coalesce(
          mother_age_int, ifelse(MAGER41 %in% 2:37, MAGER + 13, NA)
        )
      )
    }

    return(coded_data)
  }

  add_maternal_age_label = function(labeled_data) {
    # Age of mother at time of delivery. This function maps single years of
    # age into the factors that are report in more recent data sets, where 10-12
    # and 50-54 are reported as a single group.
    labeled_data = mutate(labeled_data,
        mother_age = ordered(
          NA,
          levels = data_dictionary()[['2004']][['MAGER']][['levels']],
          labels = data_dictionary()[['2004']][['MAGER']][['labels']]
        )
    )

    if('UMAGERPT' %in% names(labeled_data)) {
      # Recode individual years 10-12 and 50-54 to 12 and 50. These values
      # get mapped to factors which represent these ranges.
      labeled_data = mutate(labeled_data,
        UMAGERPT =
          ifelse(UMAGERPT %in% 10:12, 12,
          ifelse(UMAGERPT %in% 50:54, 50,
          ifelse(UMAGERPT %in% 13:49, UMAGERPT,
            NA))),
        mother_age = ordered(
          UMAGERPT,
          levels = data_dictionary()[['2004']][['MAGER']][['levels']],
          labels = data_dictionary()[['2004']][['MAGER']][['labels']]
        )
      )
    }

    if('MAGER' %in% names(labeled_data)) {
      labeled_data = mutate(labeled_data,
        mother_age = ordered(
          MAGER,
          levels = data_dictionary()[['2004']][['MAGER']][['levels']],
          labels = data_dictionary()[['2004']][['MAGER']][['labels']]
        )
      )
    }
    return(labeled_data)
  }

  add_cesarean_logical = function(labeled_data) {
    # Indicate whether the case resolved with a cesarean section using a logical,
    # with unknown cases denoted by an NA. There is a specific strategy to which fields
    # are used to determine if there was a cesarean section

    #  1. check the UME cesarean fields which are present much earlier on birth records
    #  2. then check the ME_ROUT field which was introduced in 2004
    #  3. then check the DMETH_REC field

    # There are a number of years where both 1 and 2 are present in birth records,
    # so we use a coalesce function in attempt to combine results. In years where
    # ME_ROUT is present, available values are proritized by this field. However,
    # if the field is NA or otherwise unknown, then the function falls back to
    # whatever value has already been set in the field. In many cases this will
    # include the logical interpretation of the UME fields.'

    # Start by creating the cesarean_lg field to prevent errors in mutate coalesce
    labeled_data = mutate(labeled_data, birth_via_cesarean = NA)

    if(all(c('UME_PRIMC', 'UME_REPEC') %in% names(labeled_data))) {
      labeled_data = mutate(labeled_data,
        birth_via_cesarean =
          coalesce(birth_via_cesarean,
            ifelse(UME_PRIMC == 'Yes' | UME_REPEC == 'Yes', TRUE,
            ifelse(UME_PRIMC == 'No' & UME_REPEC == 'No', FALSE,
              NA))
          )
      )
    }

    if('ME_ROUT' %in% names(labeled_data)) {
      labeled_data = mutate(labeled_data,
        birth_via_cesarean =
          coalesce(birth_via_cesarean,
            ifelse(ME_ROUT == 'Cesarean', TRUE,
            ifelse(ME_ROUT != 'Unknown or not stated', FALSE,
              NA))
          )
      )
    }

    if('DMETH_REC' %in% names(labeled_data)) {
      labeled_data = mutate(labeled_data,
        birth_via_cesarean =
          coalesce(birth_via_cesarean,
            ifelse(DMETH_REC == 'Cesarean', TRUE,
            ifelse(DMETH_REC == 'Vaginal', FALSE,
              NA))
          )
      )
    }

    return(labeled_data)
  }

  remap_BFACIL = function(labeled_data) {
    # Remap pre-1989 place of birth records to conform with the BFACIL3 field
    fields = names(labeled_data)
    if('BFACIL3' %in% fields){
      return(labeled_data)
    }

    if('PODEL' %in% fields) {
      return(
        mutate(labeled_data,
          BFACIL3 =
            recode(PODEL,
              `Hospital Births` = 'In Hospital',
              `Nonhospital Births` = 'Not in Hospital',
              `En route or born on arrival (BOA)` = 'Not in Hospital',
              .default = 'Unknown or Not Stated'
            )
        )
      )
    }

    if('PODEL1975' %in% fields) {
      return(
        mutate(labeled_data,
          BFACIL3 =
            recode(PODEL1975,
              `Hospital or Institution` = 'In Hospital',
              `Clinic, Center, or a Home` = 'Not in Hospital',
              `Names places (Drs. Offices)` = 'Not in Hospital',
              `Street Address` = 'Not in Hospital',
              .default = 'Unknown or Not Stated'
            )
        )
      )
    }

    if('ATTEND_AT_BIRTH' %in% fields) {
      return(
        mutate(labeled_data,
          BFACIL3 =
            recode(ATTEND_AT_BIRTH,
              `Births in hospitals or institutions` = 'In Hospital',
              `Births not in hospitals; Attended by physician` = 'Not in Hospital',
              `Births not in hospitals; Attended by midwife` = 'Not in Hospital',
              .default = 'Unknown or Not Stated'
            )
        )
      )
    }

    return(labeled_data)
  }

  add_hospital_logical = function(labeled_data) {
    # Convert place of birth field into a logical indicating whether the birth
    # occured in a hospital
    mutate(labeled_data,
        birth_in_hospital = ifelse(BFACIL3=='In Hospital', TRUE,
                  ifelse(BFACIL3=='Not in Hospital', FALSE,
                    NA))
      )
  }

  remap_STATENAT = function(labeled_data) {
    # Recode underlying levels of the OSTATE and STATENAT fields so that they
    # match one another. This is necessary because the OSTATE field uses two
    # character representations instead of integers.
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

  remap_CSEX = function(labeled_data) {
    # Recode underlying levels of the SEX and CSEX fields so that they
    # match one another. This is necessary because the SEX field uses
    # character representations instead of integers.
    fields = names(labeled_data)
    if(!'CSEX' %in% fields) {
      if('SEX' %in% fields) {
        # Use 2002 CSEX definitions to remap SEX codes
        lkp = setNames(
            data_dictionary()$`2002`$CSEX$levels,
            data_dictionary()$`2002`$CSEX$labels
          )
        mutate(labeled_data,
          CSEX = factor(lkp[as.character(SEX)], lkp, names(lkp))
        )
      }
      else {
        return( mutate(labeled_data, CSEX = NA) )
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
        birth_state = STATENAT,
        child_sex = CSEX
      )
  }

  #===============================================================================
  # Record Tests
  #===============================================================================
  raw_record_test = function(coded_data) {
    # Check the number of records against those listed by the CDC vital statistics
    # data dictionaries.
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

  # TODO: fix resident record checks
  resident_record_test = function(labeled_data) {
    # Check the number of records of resident births against those listed by
    # the CDC vital statistics data dictionaries.
    expec = dict$checks[[as.character(set_year)]]$resident_records

    if(is.null(expec)) {
      return(labeled_data)
    }

    testthat::expect_equal(nrow(coded_data), expec,
      info=paste("Missing resident records from data set", as.character(set_year)),
      tolerance = 0, scale=1
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


  tryCatch({
    data.table::fread(input=gz_com, stringsAsFactors=FALSE, select = sel, colClasses = col) %>%
      raw_record_test %>%
      recode_na %>%
      add_maternal_age_int %>%
      record_weighting %>%
      recode_factors %>%
      recode_flags %>%
      filter_residents %>%
      # resident_record_test %>%
      add_year %>%
      add_birth_date %>%
      add_birth_month_date %>%
      add_birth_weekday_date %>%
      add_cesarean_logical %>%
      add_maternal_age_label %>%
      remap_BFACIL %>%
      add_hospital_logical %>%
      remap_STATENAT %>%
      remap_CSEX %>%
      field_renames
  }, error = function(e) {
    print(paste("Error with", set_year, "data set."))
    print(e)
  })
}


#===============================================================================
# RECORD REDUCTION
# reduce the number of physical records by grouping and counting by a data set
# with minimal dimensions.
#===============================================================================
births = lapply(data_dictionary()$years(), function(y) {
  staged_data(y) %>%
    group_by(
      birth_month_date,
      birth_weekday_date,
      birth_state,
      birth_in_hospital,
      birth_via_cesarean,
      mother_age,
      mother_age_int,
      child_sex
    ) %>%
    summarize(cases = n())
}) %>%
  data.table::rbindlist(use.names=TRUE)

if(config$SAMPLING$enabled) {
  births = mutate(births, cases = cases / config$SAMPLING$percentage)
}

devtools::use_data(births, overwrite=TRUE)
