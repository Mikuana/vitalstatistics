get_tree = function() {
    jsonlite::fromJSON(file.path('data', 'dictionary.json'))
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


#' Vital Statistics Data Dictionary
#'
#' @return A data dictionary of the attributes that are available from a reduction
#' of the various years of data publised by the CDC is their vital statistics data sets.
#' @export
data_dictionary = function() {
    tree = get_tree()
    nodes = get_nodes()

    materialize = function() {
        "Materialize full property definitions for each year node by adding in default values if
         the year doesn't define them already. This also swaps the node order from code (field)
         coming before year, to year coming before field."
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
            'Returns a vector of years that are included in the data dictionary'
            names(dict)[grep('\\d{4}', names(dict))]
        }

        dict$checks = tree$`__checks__`

        return(dict)
    }
    materialize()
}
