library(usethis)
library(here)
library(devtools)

# create package framework
create_package(here())

# generate documentation
document()


# modify DESCRIPTION
use_description(fields = list(
  `Authors@R` = 'person("Anu", "Amallraja", email = "anu9109@gmail.com",
                          role = c("aut", "cre")',
  Title = "An R wrapper for the Cancer Genome Interpreter API",
  Language =  "es"
))

# set license
use_mit_license()
