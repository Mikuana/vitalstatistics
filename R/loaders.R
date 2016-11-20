data_dictionary = function() {
    tree = jsonlite::fromJSON(file.path('data', 'dictionary.json'))
    nodes = names(tree)

    test_node = function(node) {
        subnodes = names(tree[[node]])
        testthat::expect_true('default' %in% subnodes,
            info=sprintf("%s missing 'default' node", node))

        defaults = names(tree[[node]][['default']])
        testthat::expect_true('type' %in% defaults,
            info=sprintf("%s missing default 'type' node", node))
        testthat::expect_true('description' %in% defaults,
            info=sprintf("%s missing default 'description' node", node))

        years = subnodes[which(subnodes != 'default')]
        testthat::expect_true(length(years) > 0,
                     info=sprintf("%s has no year nodes; only default is defined", node))
        year_lg = as.integer(years) %in% 1968:year(lubridate::today())
        testthat::expect_true(
            all(year_lg),
            info=sprintf("%s has year node that isn't between 1968 and today [%s]", node,
                paste(years[!year_lg], collapse=", ")
                )
            )

        for(year in years) {
            year_attributes = names(tree[[node]][[year]])
            testthat::expect_true('start' %in% year_attributes,
                info=sprintf("%s[%s] is missing 'start' attribute", node, year))
            testthat::expect_true('end' %in% year_attributes,
                info=sprintf("%s[%s] is missing 'end' attribute", node, year))
        }
    }
    lapply(nodes, test_node)

    materialize = function() {
        "Materialize full property definitions for each year node by adding in default values if
         the year doesn't define them already. This also swaps the node order from code (field)
         coming before year, to year coming before field."
        dict = list()
        for(node in nodes) {
            defs = tree[[node]][['default']]
            subnodes = names(tree[[node]])
            years = subnodes[which(subnodes != 'default')]

            for(year in subnodes) {
                props = tree[[node]][[year]]
                dict[[year]][[node]] = c(props, defs[!names(defs) %in% names(props)])
            }
        }
        return(dict)
    }
    materialize()
}


staged_data = function(dictionary, year, column_selection=NA) {
    data_folder = file.path('data')
    if(is.na(column_selection)) { column_selection=TRUE }
    dictionary = data_dictionary()
    ydict = dictionary[[as.character(year)]][column_selection]

    recode_ordered = function(coded_data) {
        'Read definitions from data from dictionary and apply it to dataset, and construct ordered
         factor mutate statements as strings.
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


    fread(input=gz_com, stringsAsFactors=FALSE,
          select = NULL
          ) %>%
        recode_na() %>%
        recode_ordered() %>%
        # recode_flags() %>%
        add_year
}
