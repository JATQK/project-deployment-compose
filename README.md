# Project for deploying git 2 rdf via docker compose

This project purpose it to enable the deployment of the complete git2rdflab infrastructure as a docker compose target. 

## Local deployment
As of the 03rd of March 2024 the images of the target services are not yet available on docker hub as images.
Therefor they need to be built in the corresponding projects via the given scripts. This way, the required
service images will then be available locally. 

The services (especially the worker-service) have secrets, that need to be made available via environment variables.
The given .env file in this project is only an example file, which can be used as a reference, when creating your own 
.env file to then deploy the entire project via compose. The given scripts expect your .env.local file to be located
in the ./local-development/compose/.env.local location. The 'local-development' folder is part of the .gitignore,
and therefore your secrets will not be committed this way.

### Overview

This guide provides step-by-step instructions for deploying the Git2RDF project using Docker. You will download necessary repositories, install dependencies, configure environment variables, and deploy Docker images.

### Prerequisites

- Docker installed on your system
- Maven installed on your system
- Git installed on your system

### 1. Download All Necessary Repositories

Clone the following repositories to your local machine:

1. `git clone https://github.com/git2RDFLab/project-deployment-compose`
2. `git clone https://github.com/git2RDFLab/sparql-query-prototype`
3. `git clone https://github.com/git2RDFLab/ccr-worker-prototype`
4. `git clone https://github.com/git2RDFLab/ccr-listener-prototype`
5. `git clone https://github.com/git2RDFLab/database-shared-common`

### 2. Install Dependency: Database-Shared-Common

1. Navigate to the `database-shared-common` directory in a terminal.
2. Execute `mvn clean install` to install the maven artifact locally. This step makes the dependency available for other services.

### 3. Preprocess Project-Deployment-Compose

#### Configure Environment Variables

1. Navigate to the `project-deployment-compose` directory.
2. Inside `./local-development/compose/`, create a new `.env` file named `.env.local`.
3. Configure the following environment variables in `.env.local`:

    1. **GITHUB_LOGIN_APP_ID**:
        - Go to [GitHub](https://github.com) and sign in.
        - Navigate to your profile settings, then to Developer Settings at the bottom of the page.
        - Select "GitHub Apps" and click on "New GitHub App".
        - Fill in the necessary information for your app. For this setup, you can use placeholder values.
        - Once the app is created, you will find the App ID listed at the top of the app's page. This is your `GITHUB_LOGIN_APP_ID`.

    2. **GITHUB_LOGIN_APP_INSTALLATION_ID**:
        - In the GitHub App settings page, click on "Install App" in the sidebar.
        - Install the app to your account or organization as needed.
        - After installation, navigate to the installation settings page for your app. The URL will contain a number at the end (e.g., `https://github.com/settings/installations/123456`). This number is your `GITHUB_LOGIN_APP_INSTALLATION_ID`.

    3. **GITHUB_LOGIN_KEY**:
        - Still within the GitHub App settings, scroll down to the "Private keys" section.
        - Click on "Generate a private key".
        - Once the key is generated and downloaded, open it with a text editor. Remove all line breaks and spaces, making it a continuous string of characters. This is your `GITHUB_LOGIN_KEY`.

    4. **GITHUB_LOGIN_SYSTEM_USER_NAME**:
        - Your GitHub username is needed here. Simply navigate to your GitHub profile page; your username is at the top of the page and in the page's URL.

    5. **GITHUB_LOGIN_SYSTEM_USER_PERSONALACCESSTOKEN**:
        - Go back to your profile settings on GitHub, then to Developer Settings.
        - Select "Personal access tokens" and click on "Generate new token".
        - Give the token the necessary permissions, which should include at least full repository access.
        - Once the token is generated, copy it into a text editor, ensuring there are no spaces or line breaks. This is your `GITHUB_LOGIN_SYSTEM_USER_PERSONALACCESSTOKEN`.


#### Build Docker Images of the Services

Ensure all unrelated services are down and not running in the background before proceeding.

1. **Create Image for Listener-Prototype**:
   - Navigate to `ccr-listener-prototype` directory.
   - Run `mvn clean package`.
   - Run `docker build -t git2rdflab/listener-service:0.0.1-SNAPSHOT .`.

2. **Create Image for Worker-Prototype**:
   - Navigate to `ccr-worker-prototype` directory.
   - Execute the same commands as above, replacing `listener` with `worker` in the Docker build command.

3. **Create Image for SPARQL-Query-Prototype**:
   - Navigate to `sparql-query-prototype` directory.
   - Follow the same steps as above, substituting `query` for the respective service in the Docker build command.

### 4. Deploy the Docker Image

1. Open a terminal window inside the `project-deployment-compose` directory.
2. Run `docker compose --env-file ./local-development/compose/.env.local up -d`.
   - Make sure to adjust the path of your `.env.local` if necessary.


## .Env Variables
The used variables are only .env variables for the docker compose file. In the end, the .env variables only shadow
actual environment variables from the target projects. The following table only maps the explanations of the
environment variables from the corresponding projects to the corresponding .env variables in this project for the 
docker compose.

| Environment Variables                        | Description                                                                                                                                                                                                                                                                                                                             |
|----------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| POSTGRES_PASSWORD                            | The password of the postgres.                                                                                                                                                                                                                                                                                                           |
| GITHUB_LOGIN_APP_ID                          | The id of your github app, which you use for authentication to github. The id can be retrieved from the user -> settings -> developer settings -> (github app) menu. For more information see 'https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-json-web-token-jwt-for-a-github-app'. |
| GITHUB_LOGIN_APP_INSTALLATION_ID             | The installation id of your github app, which you use for authentication to github. The id can be retrieved for example via 'GET /users/{username}/installation'. For more information see 'https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-as-a-github-app-installation'.         |
| GITHUB_LOGIN_KEY                             | The private pem-base64-key generated by your github app. Var should only contain the base64. Remove the Key-Type declarations and line breaks. Will be used to sign jwt tokens. For more information see 'https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/managing-private-keys-for-github-apps'. |
| GITHUB_LOGIN_SYSTEM_USER_NAME                | Your github login username. Is used in combination with your personal access token to pull git repos from github.                                                                                                                                                                                                                       |
| GITHUB_LOGIN_SYSTEM_USER_PERSONALACCESSTOKEN | A personal access token for your github user. Is used in combination with your username to pull git repos from github.                                                                                                                                                                                                                  |
