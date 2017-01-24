# Loop through all Rmd files in studies folder and render them
for(rmd in tools::list_files_with_exts('studies', ext='Rmd', all.files = TRUE)) {
    rmarkdown::render(rmd)
}
