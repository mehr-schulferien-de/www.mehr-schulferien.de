# Deployment Guide: mehr-schulferien.de on Debian Linux

This guide provides step-by-step instructions for deploying mehr-schulferien.de to a Debian Linux server with automated GitHub deployments.

> **Note:** This deployment guide was adapted from [Chris McCord's fly_deploy project](https://github.com/chrismccord/fly_deploy) and customized for this project.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Server Setup](#part-1-server-setup)
4. [Deployment User](#part-2-deployment-user)
5. [Erlang & Elixir with mise](#part-3-erlang-and-elixir-with-mise)
6. [PostgreSQL Database](#part-4-postgresql-database)
7. [Application Secrets](#part-5-application-secrets)
8. [Systemd Service](#part-6-systemd-service)
9. [Nginx Reverse Proxy](#part-7-nginx-reverse-proxy)
10. [GitHub Self-Hosted Runner](#part-8-github-self-hosted-runner)
11. [Health Check Endpoint](#part-9-health-check-endpoint)
12. [First Deployment](#part-10-first-deployment)
13. [SSL with Let's Encrypt](#part-11-ssl-with-lets-encrypt)
14. [Automated Backups](#part-12-automated-backups)
15. [Security Hardening](#part-13-security-hardening)
16. [Daily Operations](#daily-operations)
17. [Troubleshooting](#troubleshooting)

---

## Overview

### What This Guide Builds

- **Automated deployments** - Push to `master` triggers deployment via GitHub Actions
- **Safe database migrations** - Automatic migrations with Ecto advisory locks
- **Automatic rollback** - Keeps 3 previous releases for manual rollback
- **Self-hosted GitHub Actions runner** - Build and deploy on your server

### Project-Specific Details

| Setting | Value |
|---------|-------|
| Application name | `mehr_schulferien` |
| Module name | `MehrSchulferien` |
| Domain | `www.mehr-schulferien.de` |
| Port | `4000` (configurable via `PORT` env var) |
| Erlang version | `27.3.4` |
| Elixir version | `1.18.4-otp-27` |
| Database | PostgreSQL |
| Main branch | `master` |

---

## Prerequisites

- A fresh Debian Linux server (Bookworm 12 or newer)
- SSH access with sudo privileges
- Domain `mehr-schulferien.de` pointed to your server
- GitHub repository access

---

## Part 1: Server Setup

### Step 1.1: Connect to Your Server

```bash
ssh your-admin-user@your-server-ip
```

### Step 1.2: Update System Packages

```bash
sudo apt update && sudo apt upgrade -y
```

### Step 1.3: Install Required System Packages

```bash
sudo apt install -y \
  curl \
  git \
  build-essential \
  autoconf \
  m4 \
  libncurses-dev \
  libssl-dev \
  postgresql \
  postgresql-contrib \
  nginx \
  unattended-upgrades \
  texlive-latex-base \
  texlive-fonts-recommended \
  texlive-fonts-extra \
  texlive-latex-extra \
  texlive-lang-german \
  imagemagick
```

> **Note:** LaTeX packages (`texlive-*`) are required for PDF generation (excuse letters). ImageMagick is used for image processing.

**Checkpoint:** Verify installations:
```bash
psql --version          # Should show PostgreSQL 15+
nginx -v                # Should show nginx version
git --version           # Should show git version
pdflatex --version      # Should show pdfLaTeX version
```

---

## Part 2: Deployment User

### Step 2.1: Create the Deployment User

```bash
# Create user with home directory
sudo useradd -m -s /bin/bash mehrschul2025

# Set a password
sudo passwd mehrschul2025
```

### Step 2.2: Create Application Directory Structure

```bash
# Create directories
sudo mkdir -p /home/mehrschul2025/{app,conf}
sudo chown -R mehrschul2025:mehrschul2025 /home/mehrschul2025

# As deployment user, create subdirectories
sudo -u mehrschul2025 mkdir -p /home/mehrschul2025/app/{build,release}
sudo -u mehrschul2025 mkdir -p /home/mehrschul2025/app/build/repo
```

**Checkpoint:** Verify structure:
```bash
ls -la /home/mehrschul2025/app
# Should show: build, release directories
```

---

## Part 3: Erlang and Elixir with mise

### Step 3.1: Install mise for Deployment User

```bash
# Switch to deployment user
sudo su - mehrschul2025

# Install mise
curl https://mise.run | sh

# Add mise to shell
echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
source ~/.bashrc

# Verify mise
mise --version
```

### Step 3.2: Install Erlang and Elixir

```bash
# Still as deployment user
# Install specific versions matching .tool-versions
mise use --global erlang@27.3.4
mise use --global elixir@1.18.4-otp-27

# This takes several minutes (compiles Erlang)

# Verify
elixir --version
# Should show: Elixir 1.18.4 (compiled with Erlang/OTP 27)

erl -version
# Should show: Erlang (SMP,ASYNC_THREADS) (BEAM) emulator version 15.x

# Exit to admin user
exit
```

---

## Part 4: PostgreSQL Database

### Step 4.1: Generate Secure Database Password

```bash
# Switch to deployment user
sudo su - mehrschul2025

# Generate password and create .env
DB_PASSWORD=$(openssl rand -base64 32)
DB_PASSWORD_ENCODED=$(printf '%s' "$DB_PASSWORD" | python3 -c "import sys; from urllib.parse import quote; print(quote(sys.stdin.read().strip(), safe=''))")

# Create prod.secret.exs config file
cat > /home/mehrschul2025/conf/prod.secret.exs << 'EOF'
# Production secrets - DO NOT COMMIT TO GIT
import Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise "DATABASE_URL environment variable is missing"

config :mehr_schulferien, MehrSchulferien.Repo,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise "SECRET_KEY_BASE environment variable is missing"

config :mehr_schulferien, MehrSchulferienWeb.Endpoint,
  http: [:inet6, port: String.to_integer(System.get_env("PORT") || "4000")],
  secret_key_base: secret_key_base,
  server: true
EOF

# Secure the file
chmod 600 /home/mehrschul2025/conf/prod.secret.exs

# Display password (copy this!)
echo "==============================================="
echo "DATABASE PASSWORD (needed for PostgreSQL setup):"
echo "$DB_PASSWORD"
echo "==============================================="
```

### Step 4.2: Create PostgreSQL Database and User

```bash
# In a NEW terminal as admin user
sudo -u postgres psql
```

```sql
-- Replace 'PASTE_PASSWORD_HERE' with password from above
CREATE USER mehrschul2025 WITH PASSWORD 'PASTE_PASSWORD_HERE';
CREATE DATABASE mehr_schulferien_prod OWNER mehrschul2025;

-- Verify
\l mehr_schulferien_prod
\q
```

### Step 4.3: Test Database Connection

```bash
# As deployment user
sudo su - mehrschul2025

# Set DATABASE_URL and test
export DATABASE_URL="postgresql://mehrschul2025:YOUR_PASSWORD@localhost/mehr_schulferien_prod"
psql "$DATABASE_URL" -c "SELECT version();"

exit
```

---

## Part 5: Application Secrets

### Step 5.1: Create Environment File

```bash
# As deployment user
sudo su - mehrschul2025

# Generate SECRET_KEY_BASE (at least 64 bytes)
SECRET_KEY_BASE=$(openssl rand -base64 64 | tr -d '\n')

# Create environment file for systemd
cat > /home/mehrschul2025/conf/env << EOF
# Database
DATABASE_URL=postgresql://mehrschul2025:YOUR_ENCODED_PASSWORD@localhost/mehr_schulferien_prod
POOL_SIZE=20

# Phoenix
SECRET_KEY_BASE=${SECRET_KEY_BASE}
PHX_HOST=www.mehr-schulferien.de
PORT=4000
PHX_SERVER=true

# Optional
ECTO_IPV6=false
EOF

# Secure the file
chmod 600 /home/mehrschul2025/conf/env

# Update prod.secret.exs with actual DATABASE_URL
nano /home/mehrschul2025/conf/prod.secret.exs
# Replace the placeholder password

exit
```

---

## Part 6: Systemd Service

### Step 6.1: Create Service File

```bash
# As admin user
sudo nano /etc/systemd/system/mehr-schulferien2020.service
```

Paste this content:

```ini
[Unit]
Description=MehrSchulferien Phoenix Application
After=network.target postgresql.service

[Service]
Type=simple
User=mehrschul2025
Group=mehrschul2025
WorkingDirectory=/home/mehrschul2025/app/release
EnvironmentFile=/home/mehrschul2025/conf/env
ExecStart=/home/mehrschul2025/app/release/bin/server
ExecStop=/home/mehrschul2025/app/release/bin/mehr_schulferien stop
Restart=on-failure
RestartSec=5
RemainAfterExit=no
SyslogIdentifier=mehr-schulferien

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/home/mehrschul2025/app
ReadWritePaths=/tmp

[Install]
WantedBy=multi-user.target
```

### Step 6.2: Enable the Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable mehr-schulferien2020
```

### Step 6.3: Grant Deployment User Systemd Permissions

```bash
sudo visudo -f /etc/sudoers.d/mehrschul2025
```

Add this line:

```
mehrschul2025 ALL=(ALL) NOPASSWD: /bin/systemctl restart mehr-schulferien2020.service, /bin/systemctl stop mehr-schulferien2020.service, /bin/systemctl start mehr-schulferien2020.service, /usr/bin/journalctl -u mehr-schulferien2020 *
```

---

## Part 7: Nginx Reverse Proxy

### Step 7.1: Create Nginx Configuration

```bash
sudo nano /etc/nginx/sites-available/mehr-schulferien
```

Paste this content:

```nginx
upstream mehr_schulferien {
    server 127.0.0.1:4000;
}

server {
    listen 80;
    server_name mehr-schulferien.de www.mehr-schulferien.de;

    # Redirect non-www to www
    if ($host = mehr-schulferien.de) {
        return 301 https://www.mehr-schulferien.de$request_uri;
    }

    location / {
        proxy_pass http://mehr_schulferien;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 90;

        # Increase buffer sizes for large responses
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
    }

    # WebSocket support for LiveView
    location /live {
        proxy_pass http://mehr_schulferien;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Longer timeout for WebSocket connections
        proxy_read_timeout 3600;
        proxy_send_timeout 3600;
    }

    # Health check endpoint (no caching, fast response)
    location /health {
        proxy_pass http://mehr_schulferien;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_read_timeout 5;
        access_log off;
    }

    # Static files - served directly by nginx for better performance
    location /images/ {
        alias /home/mehrschul2025/app/release/lib/mehr_schulferien-*/priv/static/images/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Client body size for file uploads
    client_max_body_size 10M;
}
```

### Step 7.2: Enable Nginx Site

```bash
sudo ln -s /etc/nginx/sites-available/mehr-schulferien /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## Part 8: GitHub Self-Hosted Runner

### Step 8.1: Create Runner on GitHub

1. Go to https://github.com/mehr-schulferien-de/www.mehr-schulferien.de
2. Click **Settings** → **Actions** → **Runners**
3. Click **New self-hosted runner**
4. Select **Linux** as OS
5. Keep this page open

### Step 8.2: Install Runner on Server

```bash
# Switch to deployment user
sudo su - mehrschul2025

# Create runner directory
mkdir -p ~/actions-runner
cd ~/actions-runner

# Download runner (check GitHub page for latest version)
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

# Extract
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# Configure (copy token from GitHub page)
./config.sh --url https://github.com/mehr-schulferien-de/www.mehr-schulferien.de --token YOUR_TOKEN
```

**During configuration:**
- Runner group: Press **Enter** (default)
- Runner name: `debian-prod`
- Labels: `production`
- Work folder: Press **Enter** (default)

### Step 8.3: Install Runner as Service

```bash
# Still as deployment user
sudo ./svc.sh install mehrschul2025
sudo ./svc.sh start
sudo ./svc.sh status

exit
```

**Checkpoint:** Refresh your GitHub Runners page - you should see the runner as "Idle" with a green dot.

---

## Part 9: Health Check Endpoint

### Step 9.1: Add Health Check Route

Add a health check endpoint to your router for monitoring and load balancer health checks.

In `lib/mehr_schulferien_web/router.ex`, add:

```elixir
# Health check endpoint (before other routes)
get "/health", HealthController, :index
```

### Step 9.2: Create Health Controller

Create `lib/mehr_schulferien_web/controllers/health_controller.ex`:

```elixir
defmodule MehrSchulferienWeb.HealthController do
  use MehrSchulferienWeb, :controller

  def index(conn, _params) do
    # Check database connectivity
    case MehrSchulferien.Repo.query("SELECT 1") do
      {:ok, _} ->
        conn
        |> put_status(:ok)
        |> json(%{status: "ok", database: "connected"})

      {:error, _} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{status: "error", database: "disconnected"})
    end
  end
end
```

This endpoint:
- Returns HTTP 200 when the application and database are healthy
- Returns HTTP 503 when the database is unreachable
- Can be used by nginx, load balancers, or monitoring systems

---

## Part 10: First Deployment

### Step 10.1: Clone and Build

```bash
# As deployment user
sudo su - mehrschul2025
cd ~/app/build

# Clone repository
git clone https://github.com/mehr-schulferien-de/www.mehr-schulferien.de.git repo
cd repo

# Copy production config
cp /home/mehrschul2025/conf/prod.secret.exs config/prod.secret.exs

# Set environment
export MIX_ENV=prod
source /home/mehrschul2025/conf/env

# Install dependencies
mix deps.get --only prod

# Compile
mix compile

# Build assets
mix assets.setup
mix assets.deploy

# Create release
mix release --overwrite
```

### Step 10.2: Deploy Release

```bash
# Move release to final location
mv _build/prod/rel/mehr_schulferien ~/app/release

# Run migrations
~/app/release/bin/mehr_schulferien eval "MehrSchulferien.ReleaseTasks.migrate"

# Start application
sudo systemctl start mehr-schulferien2020

# Check status
sudo systemctl status mehr-schulferien2020

exit
```

### Step 10.3: Verify Deployment

```bash
# Check application responds
curl http://localhost:4000
curl http://localhost:4000/health

# Check logs
sudo journalctl -u mehr-schulferien2020 -n 50
```

---

## Part 11: SSL with Let's Encrypt

### Step 11.1: Install Certbot

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### Step 11.2: Obtain Certificate

```bash
sudo certbot --nginx -d mehr-schulferien.de -d www.mehr-schulferien.de
```

Follow prompts to:
- Enter email address
- Agree to terms
- Redirect HTTP to HTTPS (recommended)

### Step 11.3: Test Auto-Renewal

```bash
sudo certbot renew --dry-run
```

---

## Part 12: Automated Backups

### Step 12.1: Configure Daily Database Backup

```bash
# As deployment user
sudo su - mehrschul2025

# Create backup directory
mkdir -p ~/backups

# Edit crontab
crontab -e
```

Add these lines:

```cron
# Daily database backup at 2 AM
0 2 * * * pg_dump -U mehrschul2025 mehr_schulferien_prod | gzip > ~/backups/mehr_schulferien_$(date +\%Y\%m\%d).sql.gz

# Clean backups older than 30 days at 3 AM
0 3 * * * find ~/backups -name "mehr_schulferien_*.sql.gz" -mtime +30 -delete
```

### Step 12.2: Pre-Deployment Backups (Optional)

To add automatic pre-deployment backups, modify `scripts/deploy.sh` to include:

```bash
# Before migrations, create backup
pg_dump -U mehrschul2025 mehr_schulferien_prod --format=custom --compress=6 \
  -f ~/backups/pre-deploy-$(date +%Y%m%d%H%M%S).dump

# Keep only last 10 pre-deployment backups
find ~/backups -name "pre-deploy-*.dump" -type f | sort -r | tail -n +11 | xargs rm -f
```

---

## Daily Operations

### View Logs

```bash
# Real-time logs
sudo journalctl -u mehr-schulferien2020 -f

# Last 100 lines
sudo journalctl -u mehr-schulferien2020 -n 100

# Today's logs
sudo journalctl -u mehr-schulferien2020 --since today

# Errors only
sudo journalctl -u mehr-schulferien2020 -p err
```

### Service Management

```bash
sudo systemctl restart mehr-schulferien2020
sudo systemctl stop mehr-schulferien2020
sudo systemctl start mehr-schulferien2020
sudo systemctl status mehr-schulferien2020
```

### Manual Deployment

To trigger a deployment manually, run the deploy script:

```bash
sudo su - mehrschul2025
cd ~/app/build/repo
./scripts/deploy.sh
```

### Rollback

The deploy script keeps 3 previous releases. To rollback:

```bash
# List available backups
ls -lt ~/app/*.backup.*

# Stop current version
sudo systemctl stop mehr-schulferien2020

# Move current release aside
mv ~/app/release ~/app/release.failed

# Restore previous release
mv ~/app/release.backup.TIMESTAMP ~/app/release

# Start
sudo systemctl start mehr-schulferien2020
```

### Database Rollback

```bash
# As deployment user
sudo su - mehrschul2025

# Rollback to specific migration version
~/app/release/bin/mehr_schulferien eval "MehrSchulferien.ReleaseTasks.rollback(MehrSchulferien.Repo, 20240101000000)"
```

### Restore Database from Backup

```bash
# Daily backup (SQL format)
gunzip -c ~/backups/mehr_schulferien_20240101.sql.gz | psql mehr_schulferien_prod

# Pre-deploy backup (custom format)
pg_restore --clean --if-exists -d mehr_schulferien_prod ~/backups/pre-deploy-20240101120000.dump
```

### IEx Remote Console

```bash
sudo su - mehrschul2025
~/app/release/bin/mehr_schulferien remote
```

---

## Troubleshooting

### Application Won't Start

```bash
# Check detailed logs
sudo journalctl -u mehr-schulferien2020 -n 200 --no-pager

# Check if port is in use
sudo netstat -tlnp | grep 4000

# Verify environment
sudo -u mehrschul2025 cat /home/mehrschul2025/conf/env

# Test release manually
sudo su - mehrschul2025
cd ~/app/release
source /home/mehrschul2025/conf/env
./bin/mehr_schulferien start
./bin/mehr_schulferien pid
./bin/mehr_schulferien stop
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
psql -U mehrschul2025 -d mehr_schulferien_prod -h localhost

# Check PostgreSQL status
sudo systemctl status postgresql

# View PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-*-main.log
```

### Assets Not Loading

```bash
# Check cache_manifest.json exists
ls -la ~/app/release/lib/mehr_schulferien-*/priv/static/cache_manifest.json

# Verify static files
ls -la ~/app/release/lib/mehr_schulferien-*/priv/static/assets/

# Check nginx can access files
sudo -u www-data ls -la ~/app/release/lib/mehr_schulferien-*/priv/static/
```

### Runner Not Connecting

```bash
sudo su - mehrschul2025
cd ~/actions-runner
sudo ./svc.sh status

# View runner logs
journalctl -u actions.runner.* -f
```

### Memory Issues

```bash
# Check memory usage
free -h

# Check application memory
ps aux | grep beam

# Increase swap if needed
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### SSL Certificate Issues

```bash
# Check certificate status
sudo certbot certificates

# Force renewal
sudo certbot renew --force-renewal

# Check nginx SSL config
sudo nginx -t
```

---

## Deployment Script Reference

The current `scripts/deploy.sh` implements:

1. **Queued deployments** - GitHub Actions queues deployments sequentially, no cancellation
2. **Git pull** - Fetches latest code from `master`
3. **Asset build** - Compiles Tailwind CSS and JavaScript
4. **Release creation** - Builds OTP release with `mix release`
5. **Service restart** - Stops before copy, starts after
6. **Release backup** - Keeps 3 previous releases
7. **Migration** - Runs `MehrSchulferien.ReleaseTasks.migrate`
8. **Logging** - Uses syslog for deployment events

---

## Summary

Your mehr-schulferien.de deployment provides:

- Automated deployments on every push to `master`
- Database migrations with advisory locks (safe for multiple nodes)
- 3 release backups for quick rollback
- Daily database backups (30-day retention)
- SSL certificates with auto-renewal
- Firewall and fail2ban protection
- Health check endpoint for monitoring
- LiveView WebSocket support

**Deployment flow:**
1. Push to `master`
2. GitHub Actions runner executes `scripts/deploy.sh`
3. New release built and deployed
4. Migrations run automatically
5. Previous release backed up

---

## References

- [Phoenix Deployment Guide](https://hexdocs.pm/phoenix/deployment.html)
- [Phoenix LiveView Deployments](https://hexdocs.pm/phoenix_live_view/deployments.html)
- [Ecto Migration Guide](https://hexdocs.pm/ecto_sql/Ecto.Migration.html)
- [erlef/setup-beam GitHub Action](https://github.com/erlef/setup-beam)
- [Fly.io Phoenix Files - GitHub Actions](https://fly.io/phoenix-files/github-actions-for-elixir-ci/)
- [mise Version Manager](https://mise.run)
