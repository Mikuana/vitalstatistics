#' Vital Statistics Data Dictionary
#'
#' @return A data dictionary of the attributes that are available from a reduction
#' of the various years of data publised by the CDC is their vital statistics data sets.
#' @export
data_dictionary = function() {
    tree = jsonlite::fromJSON(file.path('data', 'dictionary.json'))
    nodes = names(tree)

    nodes = nodes[!grepl('^__\\w+__$', nodes)]  # ignore non-field properties

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
        year_lg = as.integer(years) %in% 1968:lubridate::year(lubridate::today())
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

        dict$years = function() {
            'Returns a vector of years that are included in the data dictionary'
            names(dict)[grep('\\d{4}', names(dict))]
        }

        dict$checks = tree$`__checks__`

        return(dict)
    }
    materialize()
}
