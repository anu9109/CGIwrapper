shhh <- suppressPackageStartupMessages # It's a library, so shhh! (Credit: https://stackoverflow.com/a/52066708)

# Load libraries
shhh(library(httr))
shhh(library(jsonlite))
shhh(library(tidyverse))
shhh(library(optparse))
shhh(library(rlang))
shhh(library(here))
shhh(library(fs))


# parse input arguments
option_list <- list(
  make_option(c("-e", "--email"), action = "store", type = "character",
              help = "Email address authorized to access the CGI API"),
  make_option(c("-t", "--token"), action = "store", type = "character",
              help = "API token obtained from the CGI website"),
  make_option(c("-a", "--auth"), action = "store", type = "character", default = ".auth.json",
              help = "Hidden file containing authentication details (recommended)"), 
  make_option(c("-i", "--id"), action = "store", type = "character",
              help = "Provide an ID for the CGI job (required)"),
  make_option(c("-m", "--mut"), action = "store", type = "character", default = NULL, 
              help = "Provide input mutations as file according to CGI format (.tsv) (optional)
              Atleast one input file is required"),
  make_option(c("-c", "--cna"), action = "store", type = "character", default = NULL, 
              help = "Provide input copy numbers as file according to CGI format (.tsv) (optional)
              Atleast one input file is required"),
  make_option(c("-f",  "--fus"), action = "store", type = "character", default = NULL, 
              help = "Provide input fusions as file according to CGI format (.tsv) (optional)
              Atleast one input file is required"), 
  make_option(c("-y", "--type"), action = "store", type = "character", default = "CANCER",
              help = "Provide cancer type for the sample (optional, default %default)"),
  make_option(c("-o", "--output"), action = "store", type = "character",
              help = "Provide full path of output directory (required)")
)


# passing on command line arguments to the script
opt <- parse_args(OptionParser(option_list = option_list,
                               prog = "CGIwrapper.R",
                               description = "R wrapper for the CGI API to submit, download and delete jobs"))


## read in email and api key from .auth.json OR arguments
## args take precedence if both args and auth file are present

cgi_checkAuth <- function() {
  # check for command line args first 
  message("Checking authentication details.")
  if (!any(c(is.null(opt$email), is.null(opt$token)))) {
    email <- opt$email
    token <- opt$token
  }
  else {
    # check for .auth.json file next
    secret <- if_else(file.exists(here(".auth.json")), here(".auth.json"), opt$auth)
    if (file.exists(secret)) {
      s <- read_json(secret)
      email <- s$email
      token <- s$token
    }
    else
      abort("No authentication information provided.")
  }

    sec <- list("email" = email, "token" = token)
  return(sec)
}

auth <- cgi_checkAuth()

# storing arguments in variables for further use
cgi_email <- auth$email
cgi_token <- auth$token
id <- opt$id
mut <- opt$mut
cna <- opt$cna
fus <- opt$fus
cancer_type <- opt$type
outpath <- opt$output


## check to make sure atleast one input file has been provided
cgi_checkInput <- function(mut, cna, fus){
  message("Checking to make sure atleast one input file is provided.")
  if (!any(c(!is.null(mut), !is.null(cna), !is.null(fus)))) {
    abort("No valid input data provided.")
  }
}


## check to see if authentication info/api service are working as intended
cgi_checkApiAuth <- function(api_url, header) {
  apicheck <- GET(url = api_url,header) %>%
    status_code() %>%
    http_status()
  return(apicheck$category)
}

cgi_checkService <- function(api_url, header) {
  message("Checking authentication and API status.")
  if (cgi_checkApiAuth(api_url, header) != "Success") {
    abort("The provided authentication details do not work and/or the API service is currently down.")
  }
}


# submit job 
cgi_submitJob <- function(api_url, header, mut, cna, fus, cancer_type, id){
  r <- POST(url = api_url,
            header,
            body = list(mutations = if(is_file_empty(mut)) NULL else upload_file(mut),
                        cnas = if(is_file_empty(cna)) NULL else upload_file(cna),
                        translocations = if(is_file_empty(fus)) NULL else upload_file(fus)),
            query = list(cancer_type = cancer_type, title = id))
  job_id <- content(r)
  out <- list("job_info" = r,
              "job_id" = job_id,
              "job_url" = paste0(api_url, "/", job_id))
  message(paste0("Submitted job with ID: ", job_id, "."))
  return(out)
}


# get job status
cgi_getJobStatus <- function(job_url, header){
  status <- GET(url = job_url,
                header,
                query = list(action = "logs")) %>%
    content()
  return(status$status)
}


# download results
cgi_downloadJob <- function(job_url, header, outpath, id){
  outfile <- paste0(outpath, id, ".zip")
  download <- GET(url = job_url,
             header,
             write_disk(outfile, overwrite = T),
             query = list(action = "download"))
  message(paste0("Downloaded results at: ", outpath, id, ".zip"))
  return(download)
}

# if job has successfully finished (or errored out) then download, else wait 15s and check status again
cgi_wait <- function(job_url, header, outpath, id) {
  while(!(cgi_getJobStatus(job_url, header) %in% c("Done", "Error"))) {
    message("Waiting for job to complete, checking status again in 15s..")
    Sys.sleep(15)
    cgi_getJobStatus(job_url, header)
  }
  cgi_downloadJob(job_url, header, outpath, id)
}


# delete job 
cgi_deleteJob <- function(job_url, header){
  del <- DELETE(url = job_url,
                header)
  message("Deleted job from CGI server.")
  #return(del)
}


## run everything at once - submit job + check status + download results + delete job
cgi_run <- function(cgi_email, cgi_token, mut, cna, fus, cancer_type, id, outpath){
  api_url <- "https://www.cancergenomeinterpreter.org/api/v1"
  header <- add_headers(Authorization = paste0(cgi_email, " ", cgi_token))
  #cgi_checkAuth()
  cgi_checkService(api_url, header)
  cgi_checkInput(mut, cna, fus)
  a <- cgi_submitJob(api_url, header, mut, cna, fus, cancer_type, id)
  cgi_wait(a$job_url, header, outpath, id)
  cgi_deleteJob(a$job_url, header)
}

## call main function 
cgi_run(cgi_email, cgi_token, mut, cna, fus, cancer_type, id, outpath)


