
library(configr)
library(whisker)
library(markdown)
library(xml2)
library(yaml)

#argument for rebuild
args = commandArgs(trailingOnly=TRUE)
source(paste(args[1],"/../libs/plugin-rmarkdown.R", sep = ""))

if (length(args) > 0) {
  
  if (args[2] == "build-clean") {
    stop("build-clean", call. = FALSE)
  } else {
    stop("Argument for regenerate everything not valid use 'build-clean' insted.", call.=FALSE)
  }
}
