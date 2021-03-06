# CGIwrapper
An R wrapper for the [Cancer Genome Interpreter](https://www.cancergenomeinterpreter.org/home) REST API. 


Cancer Genome Interpreter (CGI) is designed to support the identification of tumor alterations that drive the disease and detect those that may be therapeutically actionable. CGI relies on existing knowledge collected from several resources and on computational methods that annotate the alterations in a tumor according to distinct levels of evidence. 

Please cite their paper which is available [here](https://doi.org/10.1186/s13073-018-0531-8).



This wrapper talks to the CGI API and will:  
- check API and authentication status
- submit a job given input files
- download analysis results
- delete the job from the server


### Wrapper Usage

```
Usage: CGIwrapper.R [options]
R wrapper for the CGI API to submit, download and delete jobs

Options:
	-e EMAIL, --email=EMAIL
		Email address authorized to access the CGI API

	-t TOKEN, --token=TOKEN
		API token obtained from the CGI website

	-a AUTH, --auth=AUTH
		Hidden file containing authentication details (recommended)

	-i ID, --id=ID
		Provide an ID for the CGI job (required)

	-m MUT, --mut=MUT
		Provide input mutations as file according to CGI format (.tsv) (optional)
              Atleast one input file is required

	-c CNA, --cna=CNA
		Provide input copy numbers as file according to CGI format (.tsv) (optional)
              Atleast one input file is required

	-f FUS, --fus=FUS
		Provide input fusions as file according to CGI format (.tsv) (optional)
              Atleast one input file is required

	-y TYPE, --type=TYPE
		Provide cancer type for the sample (optional, default CANCER)

	-o OUTPUT, --output=OUTPUT
		Provide full path of output directory (required)

	-h, --help
		Show this help message and exit
```



#### Obtaining API token
Users can request an API token associated with an email address. This is required to use the API service. Instructions can be found [here](https://www.cancergenomeinterpreter.org/rest_api#obtain_token).




#### Authentication
Can be provided in 2 ways. 

1. As command line arguments for the wrapper script. 
	
2. In a hidden file in the project directory itself, or any specified location (recommended).
	
Create a file named `.auth.json` and add in your authentication details with the format shown below.
	

```
{
  "email": "user@email.com",
  "token": "alphanumeric-token"
}
```

Using a hidden file is the recommended way to provide details. Note that, if you use arguments then your authentication details will be stored in your log files, which is not secure. 
If both command line arguments and .auth.json are provided, the arguments will be used. 




#### Input
Inputs can be mutations, copy numbers or fusions, each type in its own file. Atleast one file is required. 

They need to be in the format as described by CGI [here](https://www.cancergenomeinterpreter.org/faq#q13).

Example inputs are provided in the data subfolder. 




#### Output
Results are downloaded and provided as a .zip file in the specified directory. 


#### Use with Docker

For help:

`docker run -it anu9109/cgiwrapper Rscript CGIwrapper.R -h`


To run the wrapper script:
```
docker run -v /path/to/input:/path/to/input -v /path/to/.auth.json:/.auth.json -it anu9109/cgiwrapper \ 
	Rscript CGIwrapper.R \ 
		-i $ID \ 
		-m /path/to/input/muts_in.tsv \ 
		-c /path/to/input/cna_in.tsv \ 
		-f /path/to/input/fus_in.tsv \ 
		-o /path/to/output/
```

Make sure to give docker access to your input files and authentication file.




