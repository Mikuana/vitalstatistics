testthat::expect_true(
        file.exists(file.path('data', 'dictionary.json'))
    )

testthat::expect_is( get_tree(), list )


# for(node in get_notes()) {
#     subnodes = names(tree[[node]])
#     testthat::expect_true('default' %in% subnodes,
#         info=sprintf("%s missing 'default' node", node))

#     defaults = names(tree[[node]][['default']])
#     testthat::expect_true('type' %in% defaults,
#         info=sprintf("%s missing default 'type' node", node))
#     testthat::expect_true('description' %in% defaults,
#         info=sprintf("%s missing default 'description' node", node))

#     years = subnodes[which(subnodes != 'default')]
#     testthat::expect_true(length(years) > 0,
#                  info=sprintf("%s has no year nodes; only default is defined", node))
#     year_lg = as.integer(years) %in% 1968:lubridate::year(lubridate::today())
#     testthat::expect_true(
#         all(year_lg),
#         info=sprintf("%s has year node that isn't between 1968 and today [%s]", node,
#             paste(years[!year_lg], collapse=", ")
#             )
#         )
# }
