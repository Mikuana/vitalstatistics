# Overview
The purpose of this project is to use the tools of data science to better understand the way that deliveries in the United States (US) via cesarean section have changed over time. It is hoped that by better understanding these changes, patterns can be identified that will help to inform decision makers. The goal of this project is to provide objective, human-centric guidance (as opposed to machine learning algorithms) that can be used to inform policy at either the facility or system levels of health care, and ultimately reduce the rate of cesarean section in the US.

## Background
The rate of deliveries via cesarean section have steadily increased across the US for decades. This is despite the fact that the World Health Organization (WHO) stated in 1985 that the "ideal" rate of cesarean section in a population is somewhere between 10 and 15 percent ([World Health Organization 1985](https://www.ncbi.nlm.nih.gov/pubmed/2863457)). As of this writing, they maintain this position in their [News Center](http://www.who.int/mediacentre/news/releases/2015/caesarean-sections/en/).

# Audience
The first place that anyone interested in this work should look is the [markdowns](markdowns) folder of this project. This contains all of the documents produced by this project. They are written in the format of [literate programming](https://en.wikipedia.org/wiki/Literate_programming), with snippets of code and data visualizations embedded directly into the narrative. Each of these documents include the complete code-set necessary to be generated, and therefore can be easily validated, and easily updated if the data sets, models, or algorithms used in the project change. If you can read the code, it may help you understand the results, but the narrative should be descriptive enough that non-programmers can understand the reasoning and conclusions.

## Data Scientists
This project is attempted with the ultimate commitment to open data and reproducibility in mind. The raw data sources are all publicly available, the analytic data processing pipeline is completely scripted (within the same repository as this document). Interested parties are encouraged to _clone_, _fork_, perform analysis, and send _pull_ requests with any improvements that you would like to see incorporated into this work. By the virtue of [RCS](https://en.wikipedia.org/wiki/Revision_Control_System), all revisions of both the code and articles are available publicly, and all work is tracked so that contributors can get credit for their work.



## Pipeline
This project seeks to make the use of Vital Statistics birth records more accessible for data science. Specifically, this project includes processing scripts that help to download, decompress, remap, and read data into _R_, including labels where applicable.

Because the data sets made available by the CDC are over 5 GB when _compressed_, the simultaneous decompression of all data sets going back to 1968 can be problematic on the typical workstation. Furthermore, even if the fields (i.e. columns) of each year are pruned aggressively, loading hundreds of  millions of records directly into memory for analysis will overflow most workstations.

This project solves these issues via a multi-step data processing pipeline the incrementally decompresses the raw birth records data, aggressively reduces columns, and then further reduces rows after equivalent values are mapped across years. The result is a data set which can easily be shared, quickly loaded into a memory, but still rich enough to power meaningful analysis. Furthermore, this data set is delivered along with a process to generate it so that interested parties can easily add or remap data according to their own priorities and generate a new data set.

This project is intended to be used in a way where the only data that are stored on disk permanently is the original zip files, and the selected columns needed for a particular project. If you need to include additional columns, or start a new project, these scripts can help you generate new, minimized data sets, by decompressing and mapping - then discarding the decompressed raw files - one year at a time.

The files involved are in this process are as follows, in order of use:
  
  1. `dictionary.json` contains definitions and drives logic for extract and transforming data from the raw CDC files to the final reduced R data object
  1. `extract.py` the initial heavy lifter in the process, which reads lines from each raw data set one at a time, remaps them to be more friendly to R, then writes them to an output. This output is ultimately compressed in order to save space
  1. `stitch.R` an R script to read the data extracted by python, and map equivalent values together to make analysis simpler
  
Generally speaking, if the R data set does not contain data that you want to use, and you know it exists, you would
  1. read the CDC data dictionaries (you can find a link [here](make a citation))
  1. map your desired columns into the relevant years in the `dictionary.json` file
  1. delete all years of extracted staging files (following the pattern _bithsXXXX.csv.gz_) from your data folder
  1. run the `extract.py` file. This should download, decompress, and extract without needing supervision. It may take a while.
  1. modify the `stitch.R` file if there are any new values that need to be mapped, and then run it
  1. perform analysis by loading the resulting `births.Rds` file

# Disclaimer
Use of this data strictly prohibits any attempts to identify individuals. This is described in great detail on the CDC web page. I highly suggest you take this seriously, and don't try to identify individuals within this data set, _even yourself_. Really.

http://www.cdc.gov/nchs/data_access/vitalstatsonline.htm

# Dependencies


## Linux Utilities
Due to propriety file compression reasons, the native `zipfile` package in _python_ is not able to unzip all of the data sets provided by the CDC. Instead, the `subprocess` package is used to make an external call to the _linux_ `unzip` utility. If your environment doesn't support this, you'll need to do some monkey work to decompress all of the files yourself, or modify the scripts to use your local decompression tool.

In addition to zipping files from _python_, a similar type of call is made from _R_ to unzip and read files directly into memory with the `zcat` utility.

# References

- BARBER, Emma L. et al. “Contributing Indications to the Rising Cesarean Delivery Rate.” _Obstetrics and gynecology_ 118.1 (2011): 29–38. PMC. Web. 29 Oct. 2016.

- WORLD HEALTH ORGANIZATION, "Appropriate technology for birth". _Lancet_ 2.8452 (1985):436–7.
