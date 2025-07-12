# 🌸 GitLotus Deployment Guide

> **Simplified Docker Compose deployment for GitLotus infrastructure components**

---

## 🚀 First-Time Setup (Start Here!)

### Step 1: Set Up Environment Configuration

**Copy the environment template:**
```bash
cp .env .env.local
```

**Edit your configuration:**
```bash
# Use your preferred editor
nano .env.local
# or
code .env.local
# or
vim .env.local
```

**Fill in the required values:**
- ✅ Set your `DOCKER_PLATFORM` (see Platform Detection below)
- ✅ Set a secure `POSTGRES_PASSWORD`
- ✅ Configure GitHub App credentials (for worker functionality)
- ⚠️ **AI API keys are optional** - leave empty if not using AI features

### Step 2: Platform Detection (Choose Your Architecture)

**Option A: Auto-detect (Recommended)**
```bash
# Run the platform detector
chmod +x detect-platform.sh
./detect-platform.sh
```

**Option B: Manual selection**

Edit `.env.local` and uncomment the right platform:

| System Type | Platform Setting |
|-------------|------------------|
| **Windows/Linux PC** (Intel/AMD) | `DOCKER_PLATFORM=linux/amd64` |
| **Mac** (Apple Silicon M1/M2/M3) | `DOCKER_PLATFORM=linux/arm64` |
| **Raspberry Pi** (ARM v7) | `DOCKER_PLATFORM=linux/arm/v7` |

### Step 3: Deploy GitLotus

**Full deployment (recommended):**
```bash
docker compose --profile worker --env-file .env.local up -d --build --quiet-pull
```

**Testing without worker:**
```bash
docker compose --profile no-worker --env-file .env.local up -d --build --quiet-pull
```

### Step 4: Verify Deployment

**Check service status:**
```bash
docker compose --env-file .env.local ps
```

**View service logs:**
```bash
docker compose --env-file .env.local logs -f
```

**Access your services:**
- 🌐 **Listener API**: http://localhost:8080/listener-service/swagger-ui/index.html
- 🔍 **Query API**: http://localhost:7080/query-service/swagger-ui/index.html
- 🤖 **Analysis API**: http://localhost:8081/analysis-service/swagger-ui/index.html

---

## 📋 Configuration Guide

### 🔐 Required Configuration

| Setting | Description | Where to Get |
|---------|-------------|--------------|
| `POSTGRES_PASSWORD` | Database password | Create a secure password |
| `GITHUB_LOGIN_APP_ID` | GitHub App ID | [GitHub Apps Settings](https://github.com/settings/apps) |
| `GITHUB_LOGIN_APP_INSTALLATION_ID` | Installation ID | Your GitHub App installation |
| `GITHUB_LOGIN_KEY` | Private key | Download from GitHub App settings |
| `GITHUB_LOGIN_SYSTEM_USER_NAME` | GitHub username | Your GitHub username |
| `GITHUB_LOGIN_SYSTEM_USER_PERSONALACCESSTOKEN` | Personal token | [Create here](https://github.com/settings/tokens) |

### 🤖 Optional Configuration (AI Features)

| Setting | Description | Where to Get |
|---------|-------------|--------------|
| `OPENROUTER_API_KEY` | OpenRouter access | [OpenRouter Keys](https://openrouter.ai/keys) |
| `GEMINI_API_KEY` | Google Gemini access | [Gemini API](https://makersuite.google.com/app/apikey) |

### 🔧 GitHub App Setup Guide

1. **Go to GitHub Apps**: https://github.com/settings/apps
2. **Create New App** or use existing
3. **Required permissions:**
   - Repository: Read & Write
   - Issues: Read & Write  
   - Pull requests: Read & Write
   - Contents: Read
4. **Copy the values** to your `.env.local`

---

## 🎯 Daily Usage Commands

### ⚡ Quick Commands (Copy & Paste Ready)

| Action | Command |
|--------|---------|
| **🚀 Start Everything** | `docker compose --profile worker --env-file .env.local up -d --build` |
| **⏹️ Stop Everything** | `docker compose --profile worker --env-file .env.local down` |
| **🧹 Clean Reset** | `docker compose --profile worker --env-file .env.local down -v` |
| **🔄 Restart All** | `docker compose --profile worker --env-file .env.local restart` |
| **📋 View Logs** | `docker compose --env-file .env.local logs -f` |
| **📊 Check Status** | `docker compose --env-file .env.local ps` |

### 🔧 Individual Service Management

| Service | Start Command |
|---------|---------------|
| **Database Only** | `docker compose --env-file .env.local up -d postgresdb` |
| **Listener Service** | `docker compose --env-file .env.local up -d --build listener-service` |
| **Worker Service** | `docker compose --env-file .env.local up -d --build worker-service` |
| **Query Service** | `docker compose --env-file .env.local up -d --build query-service` |
| **Analysis Service** | `docker compose --env-file .env.local up -d --build analysis-service` |

### 🔄 Update Services

**Rebuild single service:**
```bash
# Update worker service with latest code
docker compose --env-file .env.local up -d --build --force-recreate worker-service
```

**Force complete rebuild:**
```bash
# Nuclear option - rebuild everything from scratch
docker compose --profile worker --env-file .env.local down -v
docker compose --profile worker --env-file .env.local up -d --build --quiet-pull
```

---

## ⚡ Shell Aliases (Power User Setup)

**Add to your `~/.bashrc` or `~/.zshrc`:**

```bash
# GitLotus shortcuts
alias glt-start="docker compose --profile worker --env-file .env.local up -d --build --quiet-pull"
alias glt-stop="docker compose --profile worker --env-file .env.local down"
alias glt-clean="docker compose --profile worker --env-file .env.local down -v && docker system prune -f"
alias glt-rebuild="docker compose --profile worker --env-file .env.local up -d --build --force-recreate --quiet-pull"
alias glt-logs="docker compose --env-file .env.local logs -f"
alias glt-status="docker compose --env-file .env.local ps"
alias glt-restart="docker compose --profile worker --env-file .env.local restart"
```

**Usage after setup:**
```bash
glt-start    # 🚀 Start everything
glt-stop     # ⏹️ Stop everything  
glt-clean    # 🧹 Clean reset
glt-logs     # 📋 View logs
glt-status   # 📊 Check status
```


## 🖥️ Interactive Setup Helper

Run the small terminal helper to guide initial setup and manage containers. The
script walks you through the following steps:
1. Choose the `.env.local` file (or provide a custom path).
2. Check that required Docker images exist.
3. Validate all mandatory environment variables.
4. Detect the Docker build platform.
5. Optionally build the images.
6. Start, restart or stop the containers through a simple menu.

```bash
python scripts/terminal_ui.py
```

---

## 🌍 Environment-Specific Deployment

### 🧪 Development Mode
```bash
# No worker, faster startup
docker compose --profile no-worker --env-file .env.local up -d --build
```

### 🏭 Production Mode
```bash
# Create production config
cp .env.local .env.production
# Edit production settings...

# Deploy with production config
docker compose --profile worker --env-file .env.production up -d --build --quiet-pull
```

### 📈 Scaling Services
```bash
# Scale worker to handle more load
docker compose --env-file .env.local up -d --scale worker-service=3

# Scale multiple services
docker compose --env-file .env.local up -d \
  --scale worker-service=3 \
  --scale query-service=2
```

---

## 🔍 Monitoring & Troubleshooting

### 📊 Health Checks

**Service status overview:**
```bash
docker compose --env-file .env.local ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"
```

**Resource usage:**
```bash
docker compose --env-file .env.local top
```

**Service health:**
```bash
# Check if services are responding
curl -f http://localhost:8080/listener-service/actuator/health
curl -f http://localhost:7080/query-service/actuator/health
curl -f http://localhost:8081/analysis-service/actuator/health
```

### 📋 Log Management

```bash
# All services (last 50 lines)
docker compose --env-file .env.local logs --tail=50

# Specific service (follow mode)
docker compose --env-file .env.local logs -f worker-service

# Error logs only
docker compose --env-file .env.local logs | grep -i error

# Filter by timestamp
docker compose --env-file .env.local logs --since="1h"
```

### 🚨 Common Issues & Solutions

| Problem | Solution |
|---------|----------|
| **Port already in use** | `docker compose --env-file .env.local down` then try again |
| **Build fails** | Check your platform setting in `.env.local` |
| **GitHub auth fails** | Verify your GitHub App credentials |
| **Services won't start** | Check logs with `docker compose --env-file .env.local logs` |
| **Out of disk space** | Run `docker system prune -f` |

### 🆘 Emergency Recovery

```bash
# Complete system reset
docker compose --profile worker --env-file .env.local down -v
docker system prune -af
docker compose --profile worker --env-file .env.local up -d --build --quiet-pull
```

---

## 🌐 Service Access Points

| Service | URL | Purpose |
|---------|-----|---------|
| **🎯 Listener API** | http://localhost:8080/listener-service/swagger-ui/index.html | Main API & webhooks |
| **🔍 Query API** | http://localhost:7080/query-service/swagger-ui/index.html | SPARQL queries & data access |
| **🤖 Analysis API** | http://localhost:8081/analysis-service/swagger-ui/index.html | AI analysis & insights |
| **🗄️ Database** | `localhost:5432` | PostgreSQL direct access |

---

## 💡 Pro Tips

> **🔧 Performance**: Use `--quiet-pull` to reduce noise during deployment
> 
> **🔒 Security**: Never commit `.env.local` files to version control
> 
> **📊 Monitoring**: Use `docker compose logs -f` to watch deployments live
> 
> **🧹 Maintenance**: Run `docker system prune` weekly to free up space
> 
> **⚡ Speed**: Set up shell aliases for commands you use daily
> 
> **🎯 Focus**: Use profiles (`worker` vs `no-worker`) to deploy only what you need
> 
> **🔄 Updates**: Use `--force-recreate` when you change environment variables

---

## 📞 Getting Help

1. **Check the logs** first: `docker compose --env-file .env.local logs`
2. **Verify configuration**: Make sure all required fields in `.env.local` are filled
3. **Test connectivity**: Use the health check URLs above
4. **Emergency reset**: Use the nuclear option commands if all else fails

**Happy deploying! 🚀**