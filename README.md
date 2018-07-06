## Embedding images
For embedding images put your images at "src/images" directory<br /> 
Then in your Rmd files embed image as per images section on following link<br />
https://rmarkdown.rstudio.com/authoring_basics.html 

## Embedding videos
For embedding youtube videos paste iframe embed code in Rmd file as follow<br />
<iframe class="youtube-player" type="text/html" src="https://www.youtube.com/embed/EjDwhcZq1z0" allowfullscreen="" height="385" frameborder="0" width="100%">
</iframe>

## Blog listing page (Full content or Teaser)
For showing full content or teaser on blog listing page there is an option for setting in "src/content/blogs_list/blogs.Rmd"<br />
teaser: "full"  (For full content) <br />
teaser: "half"  (For content as teaser)

## Path Settings
For resolving relative path issue user can adjust some configuration variables in config.toml as follow<br />
1) for a domain setup <br />
publishDir = ""<br />
logoLink = "/"<br />
[[mainMenu]]<br />
  name = "Home"<br />
  url = "/"<br />
[[mainMenu]]<br />
  name = "About"<br />
  url = "/content/pages/about"<br />
[[mainMenu]]<br />
  name = "Blogs"<br />
  url = "/content/pages/blogs"<br />

2) for github pages (when user's github page repo is "tamahagane.website")<br />
publishDir = "/tamahagane.website"<br />
logoLink = "/tamahagane.website"<br />
[[mainMenu]]<br />
  name = "Home"<br />
  url = "/tamahagane.website"<br />
[[mainMenu]]<br />
  name = "About"<br />
  url = "/tamahagane.website/content/pages/about"<br />
[[mainMenu]]<br />
  name = "Blogs"<br />
  url = "/tamahagane.website/content/pages/blogs"<br />

