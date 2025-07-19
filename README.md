# 🌸 GitLotus Deployment Guide

> **Simplified Docker Compose deployment for GitLotus infrastructure components**

---

## 🚀 Easy Setup Wizard (Recommended)

For the fastest and most reliable setup, use the interactive terminal wizard. It guides you through the entire process, from creating your configuration to launching the services.

**To start the wizard, run this command in your terminal:**
```bash
chmod +x setup.sh
./setup.sh
```

The setup wizard will help you:
- ✅ **Create & Configure:** Automatically generates your `.env.local` file.  
- 🕵️ **Validate & Detect:** Checks for required credentials and auto-detects your system’s architecture (`DOCKER_PLATFORM`).  
- ⚙️ **Manage Services:** Provides a simple menu to build, start, stop, restart, and manage all services.  
- 💣 **Purge System:** Includes an option to safely perform a full system reset.  

---

## 🛠️ Manual Setup

This method is for advanced users who prefer to manage the process manually. If you are new to the project, we strongly recommend using the Easy Setup Wizard instead.

### Step 1: Set Up Environment Configuration

1. Copy the environment template:
   ```bash
   cp .env .env.local
   ```
2. Edit your configuration with your preferred editor:
   ```bash
   nano .env.local
   ```
3. Fill in the required values using the detailed guide below.

### Step 2: Platform Detection

Edit `.env.local` and set the correct platform for your system’s architecture:

| System Type                          | Platform Setting         |
| ------------------------------------ | ------------------------ |
| Windows/Linux PC (Intel/AMD)         | `DOCKER_PLATFORM=linux/amd64` |
| Mac (Apple Silicon M1/M2/M3)         | `DOCKER_PLATFORM=linux/arm64` |
| Raspberry Pi (ARM v7)                | `DOCKER_PLATFORM=linux/arm/v7` |

### Step 3: Deploy GitLotus

- **Full deployment (with worker):**
  ```bash
  docker compose --profile worker --env-file .env.local up -d --build --quiet-pull
  ```
- **Deployment without worker (for testing):**
  ```bash
  docker compose --profile no-worker --env-file .env.local up -d --build --quiet-pull
  ```

### Step 4: Verify Deployment

- **Check service status:**
  ```bash
  docker compose --env-file .env.local ps
  ```
- **View service logs:**
  ```bash
  docker compose --env-file .env.local logs -f
  ```

---

## 📋 Configuration Guide

### 🔐 Required Configuration: A Detailed Guide

This guide will walk you through obtaining all the necessary credentials for the `.env.local` file.

#### Part 1: Database Password (`POSTGRES_PASSWORD`)

- Open your `.env.local` file.  
- Locate the line:
  ```bash
  POSTGRES_PASSWORD=your_postgres_password
  ```
- Replace `your_postgres_password` with a strong, unique password.  
  **Example:**
  ```bash
  POSTGRES_PASSWORD=aVery-Strong-and-Secure-Password123!
  ```

> 🔒 **Security Note:** Do not use a simple or common password.

#### Part 2: GitHub Credentials

The following variables require you to create and install a GitHub App.

##### Step A: Create a New GitHub App

1. Navigate to GitHub’s App settings page:  
   `https://github.com/settings/apps`
2. Click **New GitHub App**.
3. Configure:
   - **App Name:** e.g., “GitLotus Worker – [Your Name]”  
   - **Homepage URL:** e.g., `https://github.com/your-username`  
   - **Webhook:** You can uncheck **Active** for now.

##### Step B: Configure App Permissions

Grant the following repository permissions:
- **Contents:** Read-only  
- **Issues:** Read & write  
- **Pull requests:** Read & write  

Leave all other permissions as “No access”.

##### Step C: Create and Install the App

1. Under **Where can this GitHub App be installed?**, select **Only on this account**.  
2. Click **Create GitHub App**.  
3. You’ll be redirected to the app’s settings page.

##### Step D: Get App ID and Private Key

- **App ID (`GITHUB_LOGIN_APP_ID`):** Copy from the top of the app’s settings page.  
- **Private Key (`GITHUB_LOGIN_KEY`):**
  1. Scroll to **Private keys**.
  2. Click **Generate a private key** (a `.pem` file downloads).
  3. Open the `.pem` file and copy its entire contents, including the `BEGIN`/`END` lines.
  4. Paste into your `.env.local` as:
     ```bash
     GITHUB_LOGIN_KEY="-----BEGIN RSA PRIVATE KEY-----
...your-key...
-----END RSA PRIVATE KEY-----"
     ```

##### Step E: Install the App and Get Installation ID

1. Go to the **Install App** tab in your app’s settings.
2. Click **Install** next to your account or organization.
3. Choose repositories (all or select).
4. After install, note the number in the URL:
   ```
   https://github.com/settings/installations/12345678
   ```
   Copy `12345678` into `GITHUB_LOGIN_APP_INSTALLATION_ID`.

##### Step F: Get Personal Access Token (`GITHUB_LOGIN_SYSTEM_USER_PERSONALACCESSTOKEN`)

1. Visit your Personal Access Tokens page:  
   `https://github.com/settings/tokens`
2. Click **Generate new token** (classic).
3. Configure:
   - **Name:** e.g., “GitLotus System Token”  
   - **Expiration:** e.g., 90 days  
   - **Scopes:** Select **repo** (auto-selects children).
4. Click **Generate token** and copy it immediately.
5. Paste into your `.env.local`:
   ```bash
   GITHUB_LOGIN_SYSTEM_USER_PERSONALACCESSTOKEN=your_token_here
   GITHUB_LOGIN_SYSTEM_USER_NAME=your_github_username
   ```

---

## 🤖 Optional AI Configuration

| Setting               | Description           | Where to Get         |
| --------------------- | --------------------- | -------------------- |
| `OPENROUTER_API_KEY`  | OpenRouter access     | OpenRouter Keys      |
| `GEMINI_API_KEY`      | Google Gemini access  | Gemini API           |

---

## 🎯 Daily Usage Commands

While the `setup.sh` wizard provides a menu for most actions, you can also run these commands directly.

### ⚡ Quick Commands

| Action               | Command                                                                    |
| -------------------- | -------------------------------------------------------------------------- |
| 🚀 **Start Everything**  | `docker compose --profile worker --env-file .env.local up -d --build`     |
| ⏹️ **Stop Everything**   | `docker compose --profile worker --env-file .env.local down`             |
| 🧹 **Clean Reset**      | `docker compose --profile worker --env-file .env.local down -v`          |
| 🔄 **Restart All**      | `docker compose --profile worker --env-file .env.local restart`          |
| 📋 **View Logs**        | `docker compose --env-file .env.local logs -f`                           |
| 📊 **Check Status**     | `docker compose --env-file .env.local ps`                                |

---

## 🔍 Monitoring & Troubleshooting

### 📊 Health Checks

```bash
curl -f http://localhost:8080/listener-service/actuator/health
curl -f http://localhost:7080/query-service/actuator/health
curl -f http://localhost:8081/analysis-service/actuator/health
```

### 🚨 Common Issues & Solutions

| Problem                  | Solution                                                               |
| ------------------------ | ---------------------------------------------------------------------- |
| Port already in use      | Stop the conflicting app or run `docker compose down` and retry.       |
| Build fails              | Ensure `DOCKER_PLATFORM` is set correctly in `.env.local`.            |
| GitHub auth fails        | Verify your GitHub App credentials in `.env.local`.                   |
| Services won’t start     | Check logs: `docker compose logs`.                                    |
| Out of disk space        | Run `docker system prune -af` to clean up unused Docker data.         |

---

## 🆘 Emergency Recovery

```bash
docker compose --profile worker --env-file .env.local down -v
docker system prune -af
docker compose --profile worker --env-file .env.local up -d --build
```
