library(configr)
library(whisker)
library(markdown)
library(xml2)
library(yaml)

structureChanged <- FALSE
#argument for rebuild
args = commandArgs(trailingOnly=TRUE)

HRroot <- ''
BuildPath <- ''

#' Get arguments pass by execution
#' HRocket can operates in two different modes:
#'   1. Published HTML files are under the same directory structure as the HRocket root folder
#'   2. HTML generation directory is outside the HRocket folder.
#' so HRocket needs to know where is HRocket located in system
#' @param 1 Paht of bin directory of HRocket
#' @param 2 build-clean or make

if (length(args) > 0) {
  scriptLocation <- args[1]
  HRroot <- unlist(strsplit(scriptLocation, "/"))
  HRroot <- head(HRroot,-1)
  HRroot <- paste(HRroot, collapse = '/')
  
  source(paste(HRroot,"/R/plugin-rmarkdown.R", sep = ""))
  
  #Get configration from config
  tomlConfig.list <- read.config(paste(HRroot,"/config.toml", sep = ""))
  
  # Check config variable @buildpath to set static site generation directory
  if (tomlConfig.list$BuilPath != 'ROOT') {
    BuildPath <- tomlConfig.list$BuilPath
  } else {
    BuildPath <- HRroot 
  }
  
  # To check wants rebuild every thing or build only newly add RMDs 
  if (args[2] == "build-clean") {
    
    # Get parameter @build-clean 
    # Remove old static site content
    if (dir.exists(paste(BuildPath,"/static", sep = ""))) {
      buildClean <- TRUE
      unlink(paste(BuildPath,"/static", sep = ""), recursive=TRUE)
      
      if (dir.exists(paste(BuildPath,"/content", sep = ""))) {
        unlink(paste(BuildPath,"/content", sep = ""), recursive=TRUE)  
      }
      if(file.exists(paste(BuildPath,"/index.html", sep = ""))){
        file.remove(paste(BuildPath,"/index.html", sep = ""))
      }
      
    }
  } 
} else {
  stop("HRocket need some Arguments for build you static site. HRocket executed by shell script and HRocket needs to know where is actual script is located. so pass bin directory patha as frist argument and build-clean or make as second", call.=FALSE)
}

# Path to theme statis files
theme <- paste(HRroot,"/themes/", tomlConfig.list$theme, sep = "")
theme.static.folder <- paste(theme, "/static", sep = "")

# copy themes static file in public directory
if (!dir.exists(paste(BuildPath,"/static", sep = ""))) {
  file.copy(theme.static.folder, paste(BuildPath,"/", sep = "") , overwrite = TRUE, recursive=TRUE)
}

# copy images to public directory
if (!dir.exists(paste(BuildPath,"/images", sep = ""))) {
  file.copy(paste(HRroot, "/src/images", sep = "" ), paste(BuildPath,"/", sep = "") , overwrite = TRUE, recursive=TRUE)
}

# check index.Rmd exists or not
if (!file.exists(paste(HRroot,"/index.Rmd", sep = ""))) {
  stop("index.Rmd file is missing at root, please check your directory.")
}

# create index.html
if (!file.exists(paste(BuildPath,"/index.html", sep = ""))) {
  
  structureChanged <- TRUE
  
  # Render index.RMD
  markdownIndexOutput <- markDownReader(BuildPath, HRroot ,"index.Rmd", page = FALSE, post = FALSE, index = TRUE, blogs = FALSE)
  # Get mustache template's content
  pageTemplate <- readLines(paste(theme, "/templates/index.mustache", sep = ""))
  
  # prepare variables to send mustache template
  data <- list( siteName = tomlConfig.list$siteName
                , mainMenu = tomlConfig.list$mainMenu
                , dropDownMenu = tomlConfig.list$dropDownMenu
                , logo = tomlConfig.list$params$logo
                , favIcon = tomlConfig.list$params$favIcon
                , headers = markdownIndexOutput$header
                , content = markdownIndexOutput$body
                , title  = markdownIndexOutput$ptitle
                , publishDir  = tomlConfig.list$publishDir
                , logoLink  = tomlConfig.list$logoLink
  )
  
  # Print some Log where is script running
  print("Creating index.html")
  
  # Create actual output file
  writeLines(
    whisker.render(pageTemplate, data),
    paste(BuildPath, "/index.html", sep = "")
  )
  
}

# Get list of existing pages RMDs
pages <- list.files(paste(HRroot, "/src/content/pages", sep = "" ))

# check pages directory have pages or not
if(length(pages) > 0){
  # create directory for pages if not exist
  dir.create(paste(BuildPath, "/content", sep = ""), showWarnings = FALSE)
  dir.create(paste(BuildPath, "/content/pages", sep = ""), showWarnings = FALSE)
  
  for (i in 1:length(pages)) {
    rawFileName <- strsplit(pages[[i]], "[.]")[[1]][[1]]
    if (!file.exists(paste(BuildPath, "/content/pages/", rawFileName, "/index.html", sep = ""))) {
      structureChanged <- TRUE
      
      # Render page RMD file
      output <- markDownReader(BuildPath, HRroot, pages[[i]], page = TRUE, post = FALSE, index = FALSE, blogs=FALSE)
      
      # Get mustache template's content
      pageTemplate <- readLines(paste(theme, "/templates/page.mustache", sep = ""))
      # prepare variables to send mustache template
      data <- list(siteName = tomlConfig.list$siteName
                   , mainMenu = tomlConfig.list$mainMenu
                   , dropDownMenu = tomlConfig.list$dropDownMenu
                   , logo = tomlConfig.list$params$logo
                   , favIcon = tomlConfig.list$params$favIcon
                   , headers = output$header
                   , content = output$body
                   , title = output$ptitle
                   , publishDir  = tomlConfig.list$publishDir
                   , logoLink  = tomlConfig.list$logoLink
      )
      
      # Print some Log where is script running
      print(paste("Creating page ", rawFileName, sep = ""))
      
      # Create actual output file
      writeLines(
        whisker.render(pageTemplate, data),
        paste(BuildPath, "/content/pages/", rawFileName, "/index.html", sep = ""))
    }
    
  }
}

# Get list of existing post RMDs
posts <- list.files(paste(HRroot, "/src/content/posts", sep = ""))

# check post directory has posts or not
if(length(posts) > 0) {
  # create directory for posts if not exist
  dir.create(paste(BuildPath, "/content", sep = ""), showWarnings = FALSE)
  dir.create(paste(BuildPath, "/content/posts", sep = ""), showWarnings = FALSE)
  
  # create directory for pages if not exist
  dir.create(paste(BuildPath, "/content", sep = ""), showWarnings = FALSE)
  dir.create(paste(BuildPath, "/content/pages", sep = ""), showWarnings = FALSE)
  
  for (i in 1:length(posts)) {
    rawFileName <- strsplit(posts[[i]], "[.]")[[1]][[1]]
    
    if (!file.exists(paste(BuildPath, "/content/posts/", rawFileName, "/index.html", sep = ""))) {
      structureChanged <- TRUE
      
      # Render post RMD file
      output <- markDownReader(BuildPath, HRroot, posts[[i]], page = FALSE, post = TRUE, index = FALSE, blogs = FALSE)
      
      # Get mustache template's content
      postTemplate <- readLines(paste(theme, "/templates/post.mustache", sep = ""))
      
      # Get post's header configurations
      postsYamlHeader <- readRMDyamlHeaders(paste(HRroot, "/src/content/posts/", posts[[i]], sep = ""), rawFileName)
      if(length(postsYamlHeader) < 8) {
        stop('Please check your Posts Rmd files header there must be 6 parameters as follow 
             ---
             title: "Some text title"
             date: "15.02.2018"
             teaser: "Some text teaser"
             pinned: TRUE
             commentEnable: FALSE
             tags: "plotly,interactive,plot"
             ---')
      }
      # prepare variables to send mustache template
      data <- list(siteName = tomlConfig.list$siteName
                   , mainMenu = tomlConfig.list$mainMenu
                   , dropDownMenu = tomlConfig.list$dropDownMenu
                   , disqusShortname = tomlConfig.list$disqusShortname
                   , logo = tomlConfig.list$params$logo
                   , favIcon = tomlConfig.list$params$favIcon
                   , headers = output$header
                   , content = output$body
                   , title = output$ptitle
                   , commentEnable = postsYamlHeader$commentEnable
                   , tags = strsplit(postsYamlHeader$tags, ",")[[1]]
                   , postDate = postsYamlHeader$date
                   , publishDir  = tomlConfig.list$publishDir
                   , logoLink  = tomlConfig.list$logoLink
      )
      
      # Print some Log where is script running
      print(paste("Creaing post ", rawFileName, sep = ""))
      
      # Create actual output file
      writeLines(
        whisker.render(postTemplate, data),
        paste(BuildPath, "/content/posts/", rawFileName, "/index.html", sep = ""))
      } 
    }
  
  # Check if something change in site
  # If TRUE than have to rebuild blogs page to update blogs list
  if (structureChanged) {
    
    # Print some Log where is script running
    print("Creating blogs page")
    
    # Get list of all post's RMDs
    postsRMDs <- list.files(paste(HRroot, "/src/content/posts", sep = ""))
    
    # Going to put all post's configurations in a datafame
    # For applying sorting and get all pinned posts 
    allPosts <- data.frame(
      file=character(),
      title=character(),
      date=character(), 
      rawFileName=character(),
      teaser = character(),
      pinned = character(), 
      stringsAsFactors=FALSE,
      tags = character()
    )
    
    blogYamlinfo <- readRMDyamlHeaders(paste(HRroot,"/src/content/blogs_list/blogs.Rmd", sep = ""), "blogs")
    
    for (i in 1:length(postsRMDs)) {
      rawFileName <- strsplit(postsRMDs[[i]], "[.]")[[1]][[1]]
      postConfig <- readRMDyamlHeaders(paste(HRroot, "/src/content/posts/", postsRMDs[[i]], sep = ""), rawFileName)
      allPosts <- rbind(allPosts, as.data.frame( postConfig))
    }
    
    # pinned posts
    pinnedPosts <- allPosts[ which(allPosts$pinned==TRUE), ]
    numpinpost <- nrow(pinnedPosts)
    
    # unpinned posts
    unpinnedPosts <- allPosts[ which(allPosts$pinned==FALSE), ]
    numunpinpost <- nrow(unpinnedPosts)
    
    #sort by date
    finalPinnedPosts <- list()
    if(numpinpost >= 1) {
      pinnedPosts[] <- lapply(pinnedPosts, as.character)
      pinnedPosts <- pinnedPosts[order(pinnedPosts$date, decreasing = TRUE),]
      tmp.pinned <- split(pinnedPosts, seq(nrow(pinnedPosts)))
      
      for (s in 1:length(tmp.pinned)) {
        finalPinnedPosts[[s]] <- as.list(tmp.pinned[[s]])
        finalPinnedPosts[[s]]$tags <- strsplit(finalPinnedPosts[[s]]$tags, ",")[[1]] 
        if (blogYamlinfo$teaser == "full") {
          output1 <- markDownReader1(BuildPath, paste(HRroot, "/src/content/posts/", sep = ""), finalPinnedPosts[[s]]$rawFileName)
          finalPinnedPosts[[s]]$teaser <- output1$body
          finalPinnedPosts[[s]]$pheader <- output1$header
        }
      }
    }

    itemPerpage <- 10
    if (file.exists(paste(HRroot, "/src/content/blogs_list/blogs.Rmd", sep = ""))) {
      
      # Render blogs.RMD file
      blogsOutput <- markDownReader(BuildPath, HRroot, "blogs.Rmd", page = FALSE, post = FALSE, index = FALSE, blogs = TRUE)
      
      # Get header configurations
      blogYaml <- readRMDyamlHeaders(paste(HRroot,"/src/content/blogs_list/blogs.Rmd", sep = ""), "blogs")
      
      # Blogs list sort by title or date
      if (blogYaml$sortby == "title") {
        unpinnedPosts <- unpinnedPosts[order(unpinnedPosts$title, decreasing = FALSE),]
      } else {
        unpinnedPosts <- unpinnedPosts[order(unpinnedPosts$date, decreasing = TRUE),]
      }
      itemPerpage <- blogYaml$perpage_item
    } else {
      blogOutput <- list()
      
    }
    
    finalUnPinnedPosts <- list()
    pager <- FALSE
    if(numunpinpost >= 1) {
      unpinnedPosts[] <- lapply(unpinnedPosts, as.character)
      tmp.unpinned <- split(unpinnedPosts, seq(nrow(unpinnedPosts)))
      for (s in 1:length(tmp.unpinned)) {
        finalUnPinnedPosts[[s]] <- as.list(tmp.unpinned[[s]])
        finalUnPinnedPosts[[s]]$tags <- strsplit(finalUnPinnedPosts[[s]]$tags, ",")[[1]]
        if (blogYamlinfo$teaser == "full") {
          output1 <- markDownReader1(BuildPath, paste(HRroot, "/src/content/posts/", sep = ""), finalUnPinnedPosts[[s]]$rawFileName)
          finalUnPinnedPosts[[s]]$teaser <- output1$body
          finalUnPinnedPosts[[s]]$pheader <- output1$header
        }
      }
      if (length(finalUnPinnedPosts) > itemPerpage) {
        pager <- TRUE
      }
    }

    
    
    
    
    # Get mustache template's content
    postTemplate <- readLines(paste(theme, "/templates/posts_list.mustache", sep = ""))
    
    # prepare variables to send mustache template
    data <- list(siteName = tomlConfig.list$siteName
                 , mainMenu = tomlConfig.list$mainMenu
                 , dropDownMenu = tomlConfig.list$dropDownMenu
                 , logo = tomlConfig.list$params$logo
                 , favIcon = tomlConfig.list$params$favIcon
                 , headers = blogsOutput$header
                 , content = blogsOutput$body
                 , title =   blogsOutput$ptitle
                 , perPageItem = itemPerpage
                 , pinnedPost = finalPinnedPosts
                 , upinnedPost = finalUnPinnedPosts
                 , pager = pager
                 , publishDir  = tomlConfig.list$publishDir
                 , logoLink  = tomlConfig.list$logoLink
    )
    
    # create blogs directory if not exist
    #dir.create(paste(BuildPath, "/content/pages/blogs", sep = ""), showWarnings = FALSE)
    
    # Create actual output file
    writeLines(
      whisker.render(postTemplate, data),
      paste(BuildPath, "/content/pages/blogs/index.html", sep = ""))
    # patch For making blog list as home page
    #paste(BuildPath, "/index.html", sep = ""))
  }
}


if(!structureChanged){
  print("Nothing to update.")
}
