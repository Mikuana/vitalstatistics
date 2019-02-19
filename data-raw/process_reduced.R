library(dplyr)

data_dictionary = jsonlite::fromJSON(file.path('dictionary.json'))

staged_data = function(set_year, column_selection=NA) {
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
    # were 50% samples, so we impute the values as RECWT = 2
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

  add_birth_year = function(coded_data) {
    # rename YEAR to birth_year, in order to fit with existing references
    return( rename(coded_data, birth_year=YEAR) )
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

  add_maternal_age = function(coded_data) {
    # Age of mother at time of delivery. This function maps single years.
    coded_data = mutate(coded_data,  mother_age = as.integer(NA))

    if('DMAGE' %in% names(coded_data)) {
      coded_data = mutate(
        coded_data,
        mother_age = coalesce(mother_age, as.integer(DMAGE))
      )
    }

    if('UMAGERPT' %in% names(coded_data)) {
      coded_data = mutate(
        coded_data,
        mother_age = coalesce(mother_age, as.integer(UMAGERPT))
      )
    }

    if('MAGER' %in% names(coded_data)) {
      coded_data = mutate(
        coded_data,
        mother_age = coalesce(
          mother_age, ifelse(MAGER %in% 13:49, as.integer(MAGER), NA)
        )
      )
    }

    if('MAGER41' %in% names(coded_data)) {
      coded_data = mutate(
        coded_data,
        mother_age = coalesce(
          mother_age, ifelse(MAGER41 %in% 2:37, as.integer(MAGER41) + 13L, as.integer(NA))
        )
      )
    }

    return(coded_data)
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
          data_dictionary()$columns$STATENAT$metadata$levels,
          data_dictionary()$columns$STATENAT$metadata$labels
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
            data_dictionary()$columns$CSEX$metadata$levels,
            data_dictionary()$columns$CSEX$metadata$labels
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

  data_folder = file.path('~/Data/BirthCount/')
  df = feather::read_feather(file.path(data_folder, paste0(set_year, '.feather')))

  tryCatch({
    df %>%
      add_maternal_age %>%
      record_weighting %>%
      filter_residents %>%
      add_birth_year %>%
      add_birth_date %>%
      add_birth_month_date %>%
      add_birth_weekday_date %>%
      add_cesarean_logical %>%
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
births = lapply(names(data_dictionary()$data_set), function(y) {
  staged_data(y) %>%
    group_by(
      birth_month_date,
      birth_weekday_date,
      birth_state,
      birth_in_hospital,
      birth_via_cesarean,
      mother_age,
      child_sex
    ) %>%
    summarize(cases = n())
}) %>%
  data.table::rbindlist(use.names=TRUE)

devtools::use_data(births, overwrite=TRUE)




#===============================================================================
# SUPPLEMENTAL DATA SETS
#===============================================================================
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
