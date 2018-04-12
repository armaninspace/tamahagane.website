

markDownReader <- function(fileName, pageToRead = FALSE, postToRead = FALSE, index = FALSE, blogs = FALSE) {
  rawFileName <- strsplit(fileName, "[.]")[[1]][[1]]
  filePath <- ""
  outputPath <- ""
  
  if (pageToRead) {
    filePath <- "./content/pages/"
    outputPath <- paste("./public/content/pages/", rawFileName, sep = "")
    # create new directory for new page in public directory if not exist
    dir.create(outputPath, showWarnings = FALSE)
  }
  
  if (postToRead) {
    filePath <- "./content/posts/"
    outputPath <- paste("./public/content/posts/", rawFileName, sep = "")
    # create new directory for new post in public directory if not exist
    dir.create(outputPath, showWarnings = FALSE)
  }
  if (index) {
    filePath <- "./"
    outputPath <- "./public"
  }
  if (blogs) {
    filePath <- "./content/blogs_list/"
    outputPath <- paste("./public/content/pages/", rawFileName, sep = "")
    # create new directory for blogs list page in public directory if not exist
    dir.create(outputPath, showWarnings = FALSE)
  }
  
  outputFile <- paste(filePath, rawFileName, ".html", sep = "")
  outputDir_libs <- paste(filePath, rawFileName, "_files", sep = "")
  rmarkdown::render(
    paste(filePath, fileName, sep = ""),
    output_file = paste(rawFileName,".html", sep = "") ,
    quiet = TRUE,
    output_options = list(self_contained = FALSE)
  )
  
  x <- read_html(
    paste(filePath, rawFileName, ".html", sep = ""),
    encoding = "",
    options = c("RECOVER", "NOERROR", "NOBLANKS")
  )
  head <- xml_children(x)[[1]]
  body <- xml_children(x)[[2]]
  
  mustacheHeader <- list()
  pageTitle <- ""
  headCounter <- 1
  for (i in 1:length(xml_children(head))) {
    
    script <- xml_children(head)[[i]]
    TagName <- xml_name(xml_children(head)[[i]])
    if (TagName == "title") {
      pageTitle <- as.character(script)
      pageTitle <-gsub("<title>", "", pageTitle)
      pageTitle <- gsub("</title>\n", "", pageTitle)
      
    } else {
      if (!is.na( xml_attr(script,"src"))) {
        xml_set_attr(script, "src", gsub(paste(rawFileName, "_files", sep = ""), "/static", xml_attr(script, "src")))
      }
      if (!is.na(xml_attr(script,"href"))) {
        xml_set_attr(script, "href", gsub(paste(rawFileName, "_files", sep = ""), "/static", xml_attr(script, "href")))
      }
      mustacheHeader[headCounter] <- as.character(script)
      headCounter <- headCounter+1
    }
    
  }
  
  mustacheBody <- list()
  
  for (i in 1:length(xml_children(body))) {
    
    mustacheBody[i] <- as.character(xml_children(body)[[i]])
    
  }
  
  
  # file.copy(outputFile, outputPath, overwrite = TRUE)
  # file.copy(outputDir_libs, outputPath, overwrite = TRUE, recursive=TRUE)
  
  if (file.exists(outputFile)) file.remove(outputFile)
  libs <- list.files(outputDir_libs)
  for (i in 1:length(libs)) {
    if (libs[[i]] == "figure-html") {
      dir.create(paste(outputPath, "/", rawFileName, "_files/", sep = ""), showWarnings = FALSE)
      file.copy(paste(filePath, rawFileName, "_files/", libs[[i]], sep = ""), paste(outputPath, "/", rawFileName, "_files/", sep = ""), overwrite = TRUE, recursive = TRUE)
    } else {
      file.copy(paste(filePath, rawFileName, "_files/", libs[[i]], sep = ""), "./public/static", overwrite = TRUE, recursive = TRUE)
    }
  }
  unlink(outputDir_libs, recursive=TRUE)
  
  output <- list(header = mustacheHeader, body = mustacheBody, ptitle = pageTitle)
  #return header and body tags as list
  output
}

readRMDyamlHeaders <- function(file, rawFileName = "") {
  # Read in the lines of your file
  lines <- readLines(file)
  # Find the header portion contained between the --- lines. 
  header_line_nums <- which(lines == "---") + c(1, -1)
  # Create a string of just that header portion
  header <- paste(lines[seq(header_line_nums[1], 
                            header_line_nums[2])], 
                  collapse = "\n")
  # parse it as yaml, which returns a list of property values
  args <- yaml.load(header)
  args$file <- file
  args$rawFileName <- rawFileName
  return(args)
}
