# 🌸 GitLotus Deployment Guide

> **Simplified Docker Compose deployment for GitLotus infrastructure components**

---

## 🚀 Quick Start

### Deploy Complete Infrastructure

**Recommended for most use cases:**

```bash
# Deploy all services with worker
docker compose --profile worker --env-file .env.local up -d --build --quiet-pull
```

**For testing without worker:**

```bash
# Deploy services without worker
docker compose --profile no-worker --env-file .env.local up -d --build --quiet-pull
```

### Stop Infrastructure

```bash
# Stop all services (preserve data)
docker compose --profile worker --env-file .env.local down

# Stop all services + remove volumes (clean slate)
docker compose --profile worker --env-file .env.local down -v
```

### Force Rebuild & Redeploy

```bash
# Force rebuild and redeploy everything
docker compose --profile worker --env-file .env.local up -d --build --force-recreate --quiet-pull
```

## Nuclear Rebuild & Redeploy

```bash
# Force prune of all entries and datasets and redeploy everything
docker compose --profile worker --env-file .env.local down -v && \
docker compose --profile worker --env-file .env.local up -d --build --quiet-pull
```
---

## 🎯 Individual Service Management

### Deploy Single Services

| Service | Command |
|---------|---------|
| **Database** | `docker compose --env-file .env.local up -d postgresdb` |
| **Listener** | `docker compose --env-file .env.local up -d --build listener-service` |
| **Worker** | `docker compose --env-file .env.local up -d --build worker-service` |
| **Query** | `docker compose --env-file .env.local up -d --build query-service` |
| **Analysis** | `docker compose --env-file .env.local up -d --build analysis-service` |

### Update Single Services

**Quick update (rebuild & redeploy):**

```bash
# Worker service
docker compose --env-file .env.local up -d --build --force-recreate worker-service

# Query service  
docker compose --env-file .env.local up -d --build --force-recreate query-service

# Analysis service
docker compose --env-file .env.local up -d --build --force-recreate analysis-service
```

---

## ⚡ Quick Commands (Shell Aliases)

**Add these to your `~/.bashrc` or `~/.zshrc` for faster deployment:**

```bash
# GitLotus aliases
alias gitlotus-deploy="docker compose --profile worker --env-file .env.local up -d --build --quiet-pull"
alias gitlotus-stop="docker compose --profile worker --env-file .env.local down"
alias gitlotus-clean="docker compose --profile worker --env-file .env.local down -v"
alias gitlotus-rebuild="docker compose --profile worker --env-file .env.local up -d --build --force-recreate --quiet-pull"
alias gitlotus-logs="docker compose --profile worker --env-file .env.local logs"
alias gitlotus-status="docker compose --env-file .env.local ps"
```

**Usage after setting aliases:**

| Command | Description |
|---------|-------------|
| `gitlotus-deploy` | 🚀 Deploy everything |
| `gitlotus-stop` | ⏹️ Stop everything |
| `gitlotus-clean` | 🧹 Stop and clean volumes |
| `gitlotus-rebuild` | 🔄 Force rebuild everything |
| `gitlotus-logs` | 📋 View logs |
| `gitlotus-status` | 📊 Check service status |


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

### Local Development
```bash
docker compose --profile worker \
  --env-file ./local-development/compose/.env.local \
  up -d --build --quiet-pull
```

### Production
```bash
docker compose --profile worker \
  --env-file .env.production \
  up -d --build --quiet-pull
```

### Testing
```bash
docker compose --profile no-worker \
  --env-file .env.test \
  up -d --build --quiet-pull
```

---

## 🔍 Health Checks & Monitoring

### Service Status
```bash
# Check running containers
docker compose --env-file .env.local ps

# Detailed status with ports
docker compose --env-file .env.local ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"

# Resource usage
docker compose --env-file .env.local top
```

### Logs
```bash
# All services
docker compose --env-file .env.local logs

# Specific service (follow mode)
docker compose --env-file .env.local logs -f worker-service

# Last 50 lines
docker compose --env-file .env.local logs --tail=50
```

---

## 🌐 Service Access Points

Once deployed, access your services at:

| Service | URL | Description |
|---------|-----|-------------|
| **Listener API** | http://localhost:8080/listener-service/swagger-ui/index.html | Main API endpoints |
| **Query API** | http://localhost:7080/query-service/swagger-ui/index.html | SPARQL queries |
| **Analysis API** | http://localhost:9080/analysis-service/swagger-ui/index.html | Analysis results |
| **Database** | `localhost:5432` | PostgreSQL connection |

---

## 📋 Common Deployment Scenarios

### 🆕 Fresh Start (Clean Deployment)
```bash
# Complete clean deployment
docker compose --profile worker --env-file .env.local down -v
docker compose --profile worker --env-file .env.local up -d --build --quiet-pull
```

### 🔄 Update Application Code
```bash
# Rebuild and redeploy with latest code
docker compose --profile worker --env-file .env.local up -d --build --force-recreate --quiet-pull
```

### 📈 Scale Services
```bash
# Scale worker service to 3 instances
docker compose --env-file .env.local up -d --scale worker-service=3

# Scale multiple services
docker compose --env-file .env.local up -d \
  --scale worker-service=3 \
  --scale query-service=2
```

### 🔧 Development Mode
```bash
# Watch for changes (Docker Compose v2.22+)
docker compose --profile worker --env-file .env.local watch

# Development with volume mounts for hot reload
docker compose -f docker-compose.yml -f docker-compose.dev.yml \
  --env-file .env.local up -d
```

### 🚨 Emergency Restart
```bash
# Quick restart when things go wrong
docker compose --profile worker --env-file .env.local restart

# Nuclear option - rebuild everything
docker compose --profile worker --env-file .env.local down -v
docker system prune -f
docker compose --profile worker --env-file .env.local up -d --build --quiet-pull
```

---

## 💡 Tips & Best Practices

> **🔧 Performance**: Use `--quiet-pull` to reduce build noise and improve CI/CD performance
> 
> **🔒 Security**: Never commit `.env.local` files - keep them in `./local-development/compose/`
> 
> **📊 Monitoring**: Use `docker compose logs -f` to monitor deployments in real-time
> 
> **🧹 Cleanup**: Regularly run `docker system prune` to free up disk space
> 
> **⚡ Speed**: Set up shell aliases for frequently used commands