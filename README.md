<a href="https://github.com/git2RDFLab/"><img align="right" role="right" height="96" src="https://github.com/git2RDFLab/.github/blob/main/profile/images/GitLotus-logo.png?raw=true" style="height: 96px;z-index: 1000000" title="GitLotus" alt="GitLotus"/></a>

# Deploying GitLotus components

This project's purpose is to enable the deployment of the complete GitLotus infrastructure as a `docker-compose` target. 
The script starts all required components: [worker service](https://github.com/git2RDFLab/ccr-worker-prototype/), [SPARQL query service](https://github.com/git2RDFLab/sparql-query-prototype/), [listener service](https://github.com/git2RDFLab/ccr-listener-prototype/), and a [PostgreSQL database](https://www.postgresql.org/) for persistant data storage.

## Deployment and executing all components

The services (especially the worker-service) have secrets, that need to be made available via environment variables. 
The provided file `.env` in this project is only an example file, which can be used as a reference when creating your own `.env` file to then deploy the entire project via compose. 
The given scripts expect your `.env.local` file to be located at `./local-development/compose/.env.local` (description see below). 
The folder `local-development` is part of the `.gitignore`, and therefore your secrets will not be committed this way.

### Starting all components

Example command on how to run the infrastructure (a local [Docker](https://www.docker.com/) installation is required):

```ShellSession
git clone git@github.com:git2RDFLab/project-deployment-compose.git
cd project-deployment-compose
docker compose --profile worker --env-file ./local-development/compose/.env.local up -d
```

See [docker-compose.yaml](https://github.com/git2RDFLab/project-deployment-compose/blob/main/docker-compose.yaml) for the predefined configurations.

### Stopping all components

Example command on how to stop the currently running components:

```ShellSession
docker compose --profile worker down -v
```

### Accessing Web services locally

* The API definitions can be accessed via the Swagger UI of the [listener service](https://github.com/git2RDFLab/ccr-listener-prototype/):<br/>
http://localhost:8080/listener-service/swagger-ui/index.html
* The API definitions of the SPARQL queries can be accessed via the Swagger UI of the [SPARQL query service](https://github.com/git2RDFLab/sparql-query-prototype/):<br/>
http://localhost:7080/query-service/swagger-ui/index.html

## Configuration

### Configure Environment Variables

1. Navigate to the directory `project-deployment-compose`.
2. Inside `./local-development/compose/`, create a new environment file named `.env.local`.
3. Configure the environment variables in `.env.local` as described in the following.

#### `GITHUB_LOGIN_APP_ID`

- Go to [GitHub](https://github.com) and sign in.
- Navigate to your profile settings, then to Developer Settings at the bottom of the page.
- Select "GitHub Apps" and click on "New GitHub App".
- Fill in the necessary information for your app. For this setup, you can use placeholder values.
- Once the app is created, you will find the App ID listed at the top of the app's page. This is your `GITHUB_LOGIN_APP_ID`.

#### `GITHUB_LOGIN_APP_INSTALLATION_ID`

- In the GitHub App settings page, click on "Install App" in the sidebar.
- Install the app to your account or organization as needed.
- After installation, navigate to the installation settings page for your app. The URL will contain a number at the end (e.g., `https://github.com/settings/installations/123456`). This number is your `GITHUB_LOGIN_APP_INSTALLATION_ID`.

#### `GITHUB_LOGIN_KEY`

- Stay within the GitHub App settings, scroll down to the "Private keys" section.
- Click on "Generate a private key".
- Once the key is generated and downloaded, open it with a text editor. Remove all line breaks and spaces, making it a continuous string of characters. This is your `GITHUB_LOGIN_KEY`.

#### `GITHUB_LOGIN_SYSTEM_USER_NAME`

Your GitHub username is needed here. Simply navigate to your GitHub profile page; your username is at the top of the page and in the page's URL.

#### `GITHUB_LOGIN_SYSTEM_USER_PERSONALACCESSTOKEN`

- Go back to your profile settings on GitHub, then to Developer Settings.
- Select "Personal access tokens" and click on "Generate new token".
- Give the token the necessary permissions, which should include at least full repository access.
- Once the token is generated, copy it into a text editor, ensuring there are no spaces or line breaks. This is your `GITHUB_LOGIN_SYSTEM_USER_PERSONALACCESSTOKEN`.

### Variables in `.env`

The used variables are only `.env` variables needed for starting the components using docker compose. 
In the end, the `.env` variables only shadow actual environment variables from the target projects. 
The following table only maps the explanations of the environment variables from the corresponding projects to the corresponding `.env` variables in this project as needed for successfully executing docker compose.

| Environment Variables                        | Description                         |
|----------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `POSTGRES_PASSWORD`                            | The password of the PostgreSQL database.  |
| `GITHUB_LOGIN_APP_ID`                          | The id of your GitHub app, which you use for authentication to GitHub. The ID can be retrieved from the user -> settings -> developer settings -> (GitHub app) menu. [More information.](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-json-web-token-jwt-for-a-github-app). |
| `GITHUB_LOGIN_APP_INSTALLATION_ID`             | The installation ID of your GitHub app, which you use for authentication to GitHub. The ID can be retrieved for example via 'GET /users/{username}/installation'. [More information.](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-as-a-github-app-installation).         |
| `GITHUB_LOGIN_KEY`                             | The private pem-base64-key generated by your GitHub app. The value should only contain the base64 data. Remove the Key-Type declarations and line breaks. Will be used to sign JWT tokens. [More information.](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/managing-private-keys-for-github-apps). |
| `GITHUB_LOGIN_SYSTEM_USER_NAME`                | Your GitHub login username. Is used in combination with your personal access token to pull git repos from GitHub.|
| `GITHUB_LOGIN_SYSTEM_USER_PERSONALACCESSTOKEN` | A personal access token for your GitHub user. Is used in combination with your username to pull git repos from GitHub. |

## Contribute

We are happy to receive your contributions. 
Please create a pull request or an issue. 
As this tool is published under the MIT license, feel free to fork it and use it in your own projects.

## Disclaimer

This tool just temporarily stores the image data. 
It is provided "as is" and without any warranty, express or implied.


