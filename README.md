# Project for deploying git 2 rdf via docker compose

## Local deployment
As of the 03rd of March 2024 the images of the target services are not yet available on docker hub as images.
Therefor they need to be built in the corresponding projects via the given scripts. This way, the required
service images will then be available locally. 

The services (especially the worker-service) have secrets, that need to be made available via environment variables.
The given .env file in this project is only an example file, which can be used as a reference, when creating your own 
.env file to then deploy the entire project via compose. The given scripts expect your .env.local file to be located
in the ./local-development/compose/.env.local location. The 'local-development' folder is part of the .gitignore,
and therefore your secrets will not be committed this way.
