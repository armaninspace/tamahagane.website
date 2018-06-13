# HRocket Blogging for Geeks
HRocket aspires to be a static site generator that's a blogging Geek's best friend.

The name HRocket is a play on the venerable portable typewriter the Hermes Rocket.

## Design Notes
1. We should have a top-level R folder where we organize our R code
1. We should have a bin folder with has bash scripts that wrap the R code
1. The user as part of the install instructions will be required to add the bin to the path
1.  The bin folder should have:
    1. bin/hrmk -- this is the make file which will run the build process
    1. bin/hrclean -- this will delete any cache files
1. HRocket can operates in two different modes:
    1. monolithic-mode (perhaps we can find a better word) -- in this mode the published HTML files are under the same directory structure as the HRocket root folder
    1. separate-mode and this is the preferred mode, where the HTML generation directory is outside the HRocket folder 
1. Charting should be done using Plot.ly and ggplot
1. HRocket will support code embedding from Bash, C, C++, Java, Python, and R -- later we will add support for Scala, Clojure, and other languages
1. Each theme will be in a self-contained folder with a unique name
1. The theme folder will be in a folder called themes
1. The bootstrap theme will be used to build the first theme

# Path Settings
For resolving relative path issue user can adjust some configuration variables in config.toml as follow
1) for a domain setup
publishDir = ""
logoLink = "/"
[[mainMenu]]
  name = "Home"
  url = "/"
[[mainMenu]]
  name = "About"
  url = "/content/pages/about"
[[mainMenu]]
  name = "Blogs"
  url = "/content/pages/blogs"

2) for github pages (when user's github page repo is "testhrocket")
publishDir = "/testhrocket"
logoLink = "/testhrocket"
[[mainMenu]]
  name = "Home"
  url = "/testhrocket"
[[mainMenu]]
  name = "About"
  url = "/testhrocket/content/pages/about"
[[mainMenu]]
  name = "Blogs"
  url = "/testhrocket/content/pages/blogs"

