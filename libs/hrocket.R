library(configr)
library(whisker)
library(markdown)
library(xml2)
library(yaml)

structureChanged <- FALSE
#argument for rebuild
args = commandArgs(trailingOnly=TRUE)

scriptLocation <- ''
BuildPath <- ''

if (length(args) > 0) {
  scriptLocation <- args[1]
  source(paste(scriptLocation,"/../libs/plugin-rmarkdown.R", sep = ""))
  #get configration from config
  tomlConfig.list <- read.config(paste(scriptLocation,"/../config.toml", sep = ""))
  
  if (tomlConfig.list$BuilPath != 'ROOT') {
    BuildPath <- tomlConfig.list$BuilPath
  } else {
    BuildPath <- paste(scriptLocation,"/..", sep = "") 
  }
  
  if (args[2] == "build-clean") {
    if (dir.exists(paste(BuildPath,"/static", sep = ""))) {
      buildClean <- TRUE
      unlink(paste(BuildPath,"/static", sep = ""), recursive=TRUE)
      unlink(paste(BuildPath,"/content", sep = ""), recursive=TRUE)
      file.remove(paste(BuildPath,"/index.html", sep = ""))
    }
  } else {
    #stop("Argument for regenerate everything not valid use 'build-clean' insted.", call.=FALSE)
  }
}

# path to theme statis files
theme <- paste(scriptLocation,"/../themes/", tomlConfig.list$theme, sep = "")
theme.static.folder <- paste(theme, "/static", sep = "")



#path public site 
#public.folder <- "./public"

# create public directory if not exist
#dir.create(public.folder, showWarnings = FALSE)

# copy themes static file in public directory
if (!dir.exists(paste(BuildPath,"/static", sep = ""))) {
  file.copy(theme.static.folder, paste(BuildPath,"/", sep = "") , overwrite = TRUE, recursive=TRUE)
}

if (!file.exists(paste(BuildPath,"/index.html", sep = ""))) {
  structureChanged <- TRUE
  #create Index file
  markdownIndexOutput <- markDownReader(BuildPath, scriptLocation ,"index.Rmd", page = FALSE, post = FALSE, index = TRUE, blogs = FALSE)
  pageTemplate <- readLines(paste(theme, "/templates/index.mustache", sep = ""))
  
  
  data <- list( siteTitle = tomlConfig.list$title
                , socialMedia = tomlConfig.list$socialMedia
                , dropDownMenu = tomlConfig.list$dropDownMenu
                , logo = tomlConfig.list$params$logo
                , headers = markdownIndexOutput$header
                , content = markdownIndexOutput$body
                , title  = markdownIndexOutput$ptitle
  )
  print("Creating index.html")
  
  writeLines(
    whisker.render(pageTemplate, data),
    paste(BuildPath, "/index.html", sep = "")
  )
  
}


# create static pages
pages <- list.files(paste(scriptLocation, "/../src/content/pages", sep = "" ))


# create directory for pages if not exist
dir.create(paste(BuildPath, "/content", sep = ""), showWarnings = FALSE)
dir.create(paste(BuildPath, "/content/pages", sep = ""), showWarnings = FALSE)

for (i in 1:length(pages)) {
  rawFileName <- strsplit(pages[[i]], "[.]")[[1]][[1]]
  if (!file.exists(paste(BuildPath, "/content/pages/", rawFileName, "/index.html", sep = ""))) {
    structureChanged <- TRUE
    output <- markDownReader(BuildPath,scriptLocation, pages[[i]], page = TRUE, post = FALSE, index = FALSE, blogs=FALSE)
    
    pageTemplate <- readLines(paste(theme, "/templates/page.mustache", sep = ""))
    
    data <- list(siteTitle = tomlConfig.list$title
                  , socialMedia = tomlConfig.list$socialMedia
                  , dropDownMenu = tomlConfig.list$dropDownMenu
                  , logo = tomlConfig.list$params$logo
                  , headers = output$header
                  , content = output$body
                  , title = output$ptitle
    )
    print(paste("Creating page ", rawFileName, sep = ""))
    writeLines(
      whisker.render(pageTemplate, data),
      paste(BuildPath, "/content/pages/", rawFileName, "/index.html", sep = ""))
  }
  
}

# create static posts
posts <- list.files(paste(scriptLocation,"/../src/content/posts", sep = ""))

# create directory for posts if not exist
dir.create(paste(BuildPath, "/content", sep = ""), showWarnings = FALSE)
dir.create(paste(BuildPath, "/content/posts", sep = ""), showWarnings = FALSE)

for (i in 1:length(posts)) {
  rawFileName <- strsplit(posts[[i]], "[.]")[[1]][[1]]
  if (!file.exists(paste(BuildPath, "/content/posts/", rawFileName, "/index.html", sep = ""))) {
    structureChanged <- TRUE
    output <- markDownReader(BuildPath, scriptLocation ,posts[[i]], page = FALSE, post = TRUE, index = FALSE, blogs = FALSE)
    postTemplate <- readLines(paste(theme, "/templates/post.mustache", sep = ""))
    postsYamlHeader <- readRMDyamlHeaders(paste(scriptLocation, "/../src/content/posts/", posts[[i]], sep = ""), rawFileName)
    
    data <- list(siteTitle = tomlConfig.list$title
                  , socialMedia = tomlConfig.list$socialMedia
                  , dropDownMenu = tomlConfig.list$dropDownMenu
                  , disqusShortname = tomlConfig.list$disqusShortname
                  , logo = tomlConfig.list$params$logo
                  , headers = output$header
                  , content = output$body
                  , title = output$ptitle
                  , commentEnable = postsYamlHeader$commentEnable
                  , tags = strsplit(postsYamlHeader$tags, ",")[[1]]
    )
    print(paste("Creaing post ", rawFileName, sep = ""))
    writeLines(
      whisker.render(postTemplate, data),
      paste(BuildPath, "/content/posts/", rawFileName, "/index.html", sep = ""))
  } 
}

if (structureChanged) {
  
  # all posts by title and date
  print("Creating blogs page")
  
  postsRMDs <- list.files(paste(scriptLocation, "/../src/content/posts", sep = ""))
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
  for (i in 1:length(postsRMDs)) {
    rawFileName <- strsplit(postsRMDs[[i]], "[.]")[[1]][[1]]
    postConfig <- readRMDyamlHeaders(paste(scriptLocation, "/../src/content/posts/", postsRMDs[[i]], sep = ""), rawFileName)
    #allPosts <- c(allPosts,postConfig )
    allPosts <- rbind(allPosts, as.data.frame( postConfig))
  }
  
  # pinned posts
  pinnedPosts <- allPosts[ which(allPosts$pinned==TRUE), ]
  
  # unpinned posts
  unpinnedPosts <- allPosts[ which(allPosts$pinned==FALSE), ]
  
  #sort by date
  pinnedPosts[] <- lapply(pinnedPosts, as.character)
  pinnedPosts <- pinnedPosts[order(pinnedPosts$date, decreasing = TRUE),]
  tmp.pinned <- split(pinnedPosts, seq(nrow(pinnedPosts)))
  finalPinnedPosts <- list()
  for (s in 1:length(tmp.pinned)) {
    finalPinnedPosts[[s]] <- as.list(tmp.pinned[[s]])
    finalPinnedPosts[[s]]$tags <- strsplit(finalPinnedPosts[[s]]$tags, ",")[[1]] 
  }
  
  unpinnedPosts[] <- lapply(unpinnedPosts, as.character)
  
  
  itemPerpage <- 10
  if (file.exists(paste(scriptLocation, "/../src/content/blogs_list/blogs.Rmd", sep = ""))) {
    blogsOutput <- markDownReader(BuildPath, scriptLocation, "blogs.Rmd", page = FALSE, post = FALSE, index = FALSE, blogs = TRUE)
    blogYaml <- readRMDyamlHeaders(paste(scriptLocation,"/../src/content/blogs_list/blogs.Rmd", sep = ""), "blogs")
    if (blogYaml$sortby == "title") {
      unpinnedPosts <- unpinnedPosts[order(unpinnedPosts$title, decreasing = FALSE),]
    } else {
      unpinnedPosts <- unpinnedPosts[order(unpinnedPosts$date, decreasing = TRUE),]
    }
    itemPerpage <- blogYaml$perpage_item
  } else {
    blogOutput <- list()
    
  }
  
  
  tmp.unpinned <- split(unpinnedPosts, seq(nrow(unpinnedPosts)))
  finalUnPinnedPosts <- list()
  for (s in 1:length(tmp.unpinned)) {
    finalUnPinnedPosts[[s]] <- as.list(tmp.unpinned[[s]])
    finalUnPinnedPosts[[s]]$tags <- strsplit(finalUnPinnedPosts[[s]]$tags, ",")[[1]]
  }
  pager <- FALSE
  if (length(finalUnPinnedPosts) > itemPerpage) {
    pager <- TRUE
  }
  
  postTemplate <- readLines(paste(theme, "/templates/posts_list.mustache", sep = ""))
  
  data <- list(siteTitle = tomlConfig.list$title
                , socialMedia = tomlConfig.list$socialMedia
                , dropDownMenu = tomlConfig.list$dropDownMenu
                , logo = tomlConfig.list$params$logo
                , headers = blogsOutput$header
                , content = blogsOutput$body
                , title =   blogsOutput$ptitle
                , perPageItem = itemPerpage
                , pinnedPost = finalPinnedPosts
                , upinnedPost = finalUnPinnedPosts
                , pager = pager
  )
  # create blogs directory if not exist
  dir.create(paste(BuildPath, "/content/pages/blogs", sep = ""), showWarnings = FALSE)
  
  writeLines(
    whisker.render(postTemplate, data),
    paste(BuildPath, "/content/pages/blogs/index.html", sep = ""))
  
}

if(!structureChanged){
  print("Nothing to update.")
}
