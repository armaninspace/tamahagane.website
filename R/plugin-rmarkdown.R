#' A helper method to render RMD file
#' and returns html output in chunks like header, body content
#' 
#' 
#' @param buildPath string path to destination directory
#' @param HRroot string path to HRocket repository
#' @param fileName string name of file to render
#' @param pageToRead boolean TRUE if RMD is belong to pages
#' @param postToRead boolean TRUE if RMD is belong to posts
#' @param index boolean TRUE if RMD is index.RMD
#' @param blogs boolean TURE if RMD is blogs.RMD
#' @return list of html content

markDownReader <- function(pubDir, buildPath, HRroot, fileName, pageToRead = FALSE, postToRead = FALSE, index = FALSE, blogs = FALSE) {
  rawFileName <- strsplit(fileName, "[.]")[[1]][[1]]
  filePath <- ""
  outputPath <- ""
  
  # set initial varibales from where to read RMD where to output HTML
  if (pageToRead) {
    filePath <- paste(HRroot,"/src/content/pages/", sep = "")
    outputPath <- paste(buildPath, "/content/pages/", rawFileName, sep = "")
    # create new directory for new page in public directory if not exist
    dir.create(outputPath, showWarnings = FALSE)
  }
  
  if (postToRead) {
    filePath <- paste(HRroot,"/src/content/posts/", sep = "")
    outputPath <- paste(buildPath,"/content/posts/", rawFileName, sep = "")
    # create new directory for new post in public directory if not exist
    dir.create(outputPath, showWarnings = FALSE)
  }
  if (index) {
    filePath <- paste(HRroot, "/", sep = "") 
    outputPath <- buildPath
  }
  if (blogs) {
    filePath <- paste(HRroot, "/src/content/blogs_list/", sep = "")
    outputPath <- paste(buildPath, "/content/pages/", rawFileName, sep = "")
    # create new directory for blogs list page in public directory if not exist
    dir.create(outputPath, showWarnings = FALSE)
  }

  outputFile <- paste(filePath, rawFileName, ".html", sep = "")
  
  outputDir_libs <- paste(filePath, rawFileName, "_files", sep = "")
 
  # Render RMD using rmarkdown
  rmarkdown::render(
    paste(filePath, fileName, sep = ""),
    output_file = paste(rawFileName,".html", sep = "") ,
    quiet = TRUE,
    output_options = list(self_contained = FALSE)
  )
  
  #read rmarkdown output
  x <- read_html(
    paste(filePath, rawFileName, ".html", sep = ""),
    encoding = "",
    options = c("RECOVER", "NOERROR", "NOBLANKS")
  )
  
  # Get HTML output in chucks list
  head <- xml_children(x)[[1]]
  body <- xml_children(x)[[2]]
  
  mustacheHeader <- list()
  pageTitle <- ""
  headCounter <- 1
  
  # rmarkdow create single html file and one directory for libraries
  # all js and css libaraies include in html from output libraries directory
  # HRocket need to update all scripts src or href atributes value
  # to include libraries from satatic site's static directory
  for (i in 1:length(xml_children(head))) {
    
    script <- xml_children(head)[[i]]
    TagName <- xml_name(xml_children(head)[[i]])
    if (TagName == "title") {
      pageTitle <- as.character(script)
      pageTitle <-gsub("<title>", "", pageTitle)
      pageTitle <- gsub("</title>\n", "", pageTitle)
      
    } else {
      if (!is.na( xml_attr(script,"src"))) {
        xml_set_attr(script, "src", gsub(paste(rawFileName, "_files", sep = ""), paste(pubDir, "/static", sep = ''), xml_attr(script, "src")))
      }
      if (!is.na(xml_attr(script,"href"))) {
        xml_set_attr(script, "href", gsub(paste(rawFileName, "_files", sep = ""), paste(pubDir, "/static", sep = ''), xml_attr(script, "href")))
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
  
  # remove rmarkdown html output
  if (file.exists(outputFile)) file.remove(outputFile)
  
  # copy all libraries in to satic folder of destination
  # if markdown output has some figures than copy figures into same directory as output.html
  libs <- list.files(outputDir_libs)
  for (i in 1:length(libs)) {
    if (libs[[i]] == "figure-html") {
      filesDIR <- paste(outputPath, "/", rawFileName, "_files/", sep = "")
      figuresDIR <- paste(outputPath, "/", rawFileName, "_files/" , "figure-html", sep = "")
      dir.create(filesDIR, showWarnings = FALSE)
      #dir.create(figuresDIR, showWarnings = FALSE)
      
      file.copy(paste(filePath, rawFileName, "_files/", libs[[i]], sep = ""), filesDIR, overwrite = TRUE, recursive = TRUE)
    } else {
      file.copy(paste(filePath, rawFileName, "_files/", libs[[i]], sep = ""), paste(buildPath, "/static",sep = ""), overwrite = TRUE, recursive = TRUE)
    }
  }
  #delete rmarkdown output files
  unlink(outputDir_libs, recursive=TRUE)
  
  output <- list(header = mustacheHeader, body = mustacheBody, ptitle = pageTitle)
  #return header and body tags as list
  output
}


#' @method readRMDyamlHeaders()
#'   to read yaml headers from RMD file
#'    
#' @param file string path of RMD file
#' @param rawFileName string file name
#' 
#' @return list yaml headers
readRMDyamlHeaders <- function(file, rawFileName = "") {
  # Read in the lines of your file
  lines <- readLines(file, warn=FALSE)
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


markDownReader1 <- function(pubDir, BuildPath, filePath, rawFileName) {
  # For droping figures to blogs directory
  outputPath <- paste(BuildPath,"/content/pages/blogs/", sep = "")
  # patch For droping figures to public directory
  #outputPath <- BuildPath
  # create new directory for new post in public directory if not exist
  dir.create(outputPath, showWarnings = FALSE)
  
  outputFile <- paste(filePath, rawFileName, ".html", sep = "")
  
  outputDir_libs <- paste(filePath, rawFileName, "_files", sep = "")
  
  # Render RMD using rmarkdown
  rmarkdown::render(
    paste(filePath, rawFileName, ".Rmd", sep = ""),
    output_file = paste(rawFileName,".html", sep = "") ,
    quiet = TRUE,
    output_options = list(self_contained = FALSE)
  )
  
  #read rmarkdown output
  x <- read_html(
    paste(filePath, rawFileName, ".html", sep = ""),
    encoding = "",
    options = c("RECOVER", "NOERROR", "NOBLANKS")
  )
  
  # Get HTML output in chucks list
  head <- xml_children(x)[[1]]
  body <- xml_children(x)[[2]]
  
  mustacheHeader <- list()
  pageTitle <- ""
  headCounter <- 1
  
  # rmarkdow create single html file and one directory for libraries
  # all js and css libaraies include in html from output libraries directory
  # HRocket need to update all scripts src or href atributes value
  # to include libraries from satatic site's static directory
  for (i in 1:length(xml_children(head))) {
    
    script <- xml_children(head)[[i]]
    TagName <- xml_name(xml_children(head)[[i]])
    if (TagName == "title") {
      pageTitle <- as.character(script)
      pageTitle <-gsub("<title>", "", pageTitle)
      pageTitle <- gsub("</title>\n", "", pageTitle)
      
    } else {
      if (!is.na( xml_attr(script,"src"))) {
        xml_set_attr(script, "src", gsub(paste(rawFileName, "_files", sep = ""), paste(pubDir, "/static", sep = ''), xml_attr(script, "src")))
      }
      if (!is.na(xml_attr(script,"href"))) {
        xml_set_attr(script, "href", gsub(paste(rawFileName, "_files", sep = ""), paste(pubDir, "/static", sep = ''), xml_attr(script, "href")))
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
  
  # remove rmarkdown html output
  if (file.exists(outputFile)) file.remove(outputFile)
  
  # copy all libraries in to satic folder of destination
  # if markdown output has some figures than copy figures into same directory as output.html
  libs <- list.files(outputDir_libs)
  for (i in 1:length(libs)) {
    if (libs[[i]] == "figure-html") {
      filesDIR <- paste(outputPath, "/", rawFileName, "_files/", sep = "")
      figuresDIR <- paste(outputPath, "/", rawFileName, "_files/" , "figure-html", sep = "")
      dir.create(filesDIR, showWarnings = FALSE)
      #dir.create(figuresDIR, showWarnings = FALSE)
      
      file.copy(paste(filePath, rawFileName, "_files/", libs[[i]], sep = ""), filesDIR, overwrite = TRUE, recursive = TRUE)
    } else {
      file.copy(paste(filePath, rawFileName, "_files/", libs[[i]], sep = ""), paste(BuildPath, "/static",sep = ""), overwrite = TRUE, recursive = TRUE)
    }
  }
  #delete rmarkdown output files
  unlink(outputDir_libs, recursive=TRUE)
  
  output <- list(header = mustacheHeader, body = mustacheBody, ptitle = pageTitle)
  #return header and body tags as list
  output
}
