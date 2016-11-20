One of the main challenges in working with the vital statistics records is that the size of the data sets exceeds the practical limitations of a work station. When all of the data sets are downloaded, the (extremely efficiently) compressed data exceeds 5 GB.

Because of certain design choices in the development of R, it is not a platform well suited for handling of large data sets, and therefore we use Python to reduce the size of these data sets before passing them on to R for further processing.

Python performs three main functions in this process: 

  1. Obtain raw data sets from the CDC FTP servers
  
  1. Unpack raw data sets (using external system utilies)
  
  1. Read raw data set line-by-line, and write only the fields that we are interested in keeping, as specified by the `data/dictionary.json` file

  1. Recompress the much reduced data set

At this point, R is then used to read, transform, stich yearly data sets together, and then further reduce records.
