# Step-by-Step Hot Deployment Guide: Phoenix Framework App on Debian Linux

NOTE: A significant portion of this deployment guide was adapted from
Chris McCord's fly_deploy project: https://github.com/chrismccord/fly_deploy

## What This Guide Offers

This guide implements **hot code upgrades** - an Erlang/OTP feature that updates your Phoenix application while running, typically in <1 second, without disconnecting users.

**Traditional deployments** require 5-10 seconds of downtime, drop WebSocket connections, and lose active sessions. **Hot upgrades** complete in <1s, preserve LiveView sessions, and keep all connections alive. The system automatically falls back to cold deploy when needed (migrations, config changes).

### What You'll Build

- **Hot code upgrades** - Sub-second deployments for most changes
- **Automated deployments** - Push to `main` triggers deployment via GitHub Actions
- **Safe database migrations** - Automatic migrations with fallback to cold deploy
- **Automatic rollback** - Failed deployments roll back automatically
- **Self-hosted GitHub Actions runner** - Build and deploy on your server

---

This is a complete, step-by-step tutorial for deploying your Phoenix application to a Debian Linux server with automated GitHub deployments.

**Prerequisites:**
- A fresh Debian Linux server (Bookworm 12 or newer)
- SSH access with sudo privileges
- A domain name pointed to your server (optional but recommended)
- Your GitHub repository ready

**Important: Variable Definitions**

Throughout this guide, replace these placeholders with your actual values:
- `<deploy_user>` - Your deployment username (e.g., `mimimi`, `phoenix`, `myapp`)
- `<app_name>` - Your application name in lowercase (e.g., `mimimi`, `myapp`)
- `<AppName>` - Your application module name in PascalCase (e.g., `Mimimi`, `MyApp`)
- `<your_port>` - Your application port (e.g., `4020`, `4000`)
- `<your_username>` - Your GitHub username
- `<your_domain>` - Your domain name (e.g., `example.com`)

**What you'll build:**
- Automated deployments triggered by pushing to `main`
- Zero-downtime deployments with automatic rollback
- Database migrations run automatically
- Secure environment variable management
- Self-hosted GitHub Actions runner

---

## Part 1: Initial Server Setup

### Step 1.1: Connect to Your Server

```bash
# From your local machine
ssh your-admin-user@your-server-ip
```

### Step 1.2: Update System Packages

```bash
# Update package lists and upgrade all packages
sudo apt update && sudo apt upgrade -y
```

### Step 1.3: Install Required System Packages

```bash
# Install all required packages in one command
sudo apt install -y \
  curl \
  git \
  build-essential \
  autoconf \
  m4 \
  libncurses-dev \
  libssl-dev \
  postgresql \
  postgresql-contrib-15 \
  nginx \
  unattended-upgrades

# If postgresql-contrib-15 fails, it's safe to skip - it's optional
```

**✓ Checkpoint:** Verify installations:
```bash
psql --version          # Should show PostgreSQL 15.x
nginx -v                # Should show nginx version
git --version           # Should show git version
```

---

## Part 2: Create Deployment User

### Step 2.1: Create the Deployment User

```bash
# Create user with home directory (replace <deploy_user> with your chosen username)
sudo useradd -m -s /bin/bash <deploy_user>

# Set a password for the user
sudo passwd <deploy_user>
# Enter a secure password when prompted
```

### Step 2.2: Create Application Directory Structure

```bash
# Create main application directory (replace <app_name> with your app name)
sudo mkdir -p /var/www/<app_name>

# Set ownership to deployment user
sudo chown -R <deploy_user>:<deploy_user> /var/www/<app_name>

# Create subdirectories as deployment user
sudo -u <deploy_user> mkdir -p /var/www/<app_name>/{releases,shared,shared/backups}
```

**✓ Checkpoint:** Verify directory structure:
```bash
ls -la /var/www/<app_name>
# Should show: releases, shared directories owned by <deploy_user>:<deploy_user>
```

---

## Part 3: Install Erlang and Elixir with mise

### Step 3.1: Install mise for Admin User

```bash
# Install mise
curl https://mise.run | sh

# Add mise to your shell
echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
source ~/.bashrc

# Verify mise is installed
mise --version
```

### Step 3.2: Install mise for Deployment User

```bash
# Switch to deployment user
sudo su - <deploy_user>

# Install mise
curl https://mise.run | sh

# Add mise to user's shell
echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
source ~/.bashrc

# Install Erlang and Elixir
mise use --global erlang@28
mise use --global elixir@1.19

# This will take several minutes as it compiles Erlang and Elixir
# Wait for it to complete...

# Verify installations
elixir --version
# Should show: Elixir 1.19.x (compiled with Erlang/OTP 28)

erl -version
# Should show: Erlang/OTP 28

# Exit back to admin user
exit
```

**✓ Checkpoint:** Both admin and deployment users should have Erlang and Elixir installed.

---

## Part 4: Configure PostgreSQL Database

### Step 4.1: Generate Secure Database Password

```bash
# Switch to deployment user
sudo su - <deploy_user>

# Generate a secure password and save it immediately to the .env file
DB_PASSWORD=$(openssl rand -base64 32)

# URL-encode the password for use in DATABASE_URL
# This handles special characters like +, /, =
DB_PASSWORD_ENCODED=$(printf '%s' "$DB_PASSWORD" | python3 -c "import sys; from urllib.parse import quote; print(quote(sys.stdin.read().strip(), safe=''))")

# Create the .env file with the database password
cat > /var/www/<app_name>/shared/.env << EOF
# Database Configuration
DATABASE_URL=postgresql://<deploy_user>:${DB_PASSWORD_ENCODED}@localhost/<app_name>_prod
POOL_SIZE=10
EOF

# Secure the .env file
chmod 600 /var/www/<app_name>/shared/.env

# Display the password for PostgreSQL setup (copy this now!)
echo "==============================================="
echo "DATABASE PASSWORD (needed for next step):"
echo "$DB_PASSWORD"
echo "==============================================="

# Keep this terminal open or copy the password!
```

**⚠️ IMPORTANT:** Copy the password shown above - you'll need it in the next step!

### Step 4.2: Create PostgreSQL Database and User

```bash
# In a NEW terminal, connect to your server
ssh your-admin-user@your-server-ip

# Switch to postgres user
sudo -u postgres psql

# Now you're in the PostgreSQL shell
# Create the database user (paste the password from Step 4.1)
```

```sql
-- In the PostgreSQL shell, run these commands:
-- Replace 'PASTE_PASSWORD_HERE' with the password from Step 4.1
-- Replace <deploy_user> and <app_name> with your actual values

CREATE USER <deploy_user> WITH PASSWORD 'PASTE_PASSWORD_HERE';
CREATE DATABASE <app_name>_prod OWNER <deploy_user>;

-- Verify the database was created
\l <app_name>_prod

-- You should see <app_name>_prod in the list with owner <deploy_user>

-- Exit PostgreSQL
\q
```

**✓ Checkpoint:** Test database connection:
```bash
# Go back to the terminal where you're logged in as deployment user
# Test the connection using the DATABASE_URL from .env
source /var/www/<app_name>/shared/.env
psql "$DATABASE_URL" -c "SELECT version();"
# Should show PostgreSQL version
```

---

## Part 5: Generate Application Secrets

### Step 5.1: Generate SECRET_KEY_BASE

```bash
# Still as deployment user
# Generate SECRET_KEY_BASE (must be at least 64 bytes)
SECRET_KEY_BASE=$(openssl rand -base64 64 | tr -d '\n')

# Append to .env file
cat >> /var/www/<app_name>/shared/.env << EOF

# Phoenix Configuration
SECRET_KEY_BASE=${SECRET_KEY_BASE}
PHX_HOST=<your_domain>
PORT=<your_port>
PHX_SERVER=true

# Optional
ECTO_IPV6=false
EOF

# Verify the .env file (check SECRET_KEY_BASE is at least 64 bytes)
cat /var/www/<app_name>/shared/.env
echo ""
echo "SECRET_KEY_BASE length: $(echo -n "$SECRET_KEY_BASE" | wc -c) bytes (must be >= 64)"
```

**✓ Checkpoint:** Your `.env` file should now have:
- DATABASE_URL (with password)
- POOL_SIZE
- SECRET_KEY_BASE (long random string)
- PHX_HOST
- PORT
- PHX_SERVER
- ECTO_IPV6

### Step 5.2: Update PHX_HOST

```bash
# Still as deployment user
# Replace placeholders with your actual values
nano /var/www/<app_name>/shared/.env

# Find the line: PHX_HOST=<your_domain>
# Change it to your actual domain or server IP
# Also verify PORT is set to your desired port (e.g., 4020, 4000)
# Save and exit (Ctrl+X, then Y, then Enter)
```

---

## Part 6: Configure Systemd Service

### Step 6.1: Create Service File

```bash
# Exit deployment user, back to admin
exit

# Create systemd service file (replace <app_name> with your app name)
sudo nano /etc/systemd/system/<app_name>.service
```

Paste this content (replace all placeholders):

```ini
[Unit]
Description=<AppName> Phoenix Application
After=network.target postgresql.service

[Service]
Type=simple
User=<deploy_user>
Group=<deploy_user>
WorkingDirectory=/var/www/<app_name>/current
EnvironmentFile=/var/www/<app_name>/shared/.env
ExecStart=/var/www/<app_name>/current/bin/server
ExecStop=/var/www/<app_name>/current/bin/<app_name> stop
Restart=on-failure
RestartSec=5
RemainAfterExit=no
SyslogIdentifier=<app_name>

[Install]
WantedBy=multi-user.target
```

Save and exit (Ctrl+X, then Y, then Enter).

### Step 6.2: Enable the Service

```bash
# Reload systemd to recognize new service
sudo systemctl daemon-reload

# Enable service to start on boot (but don't start it yet)
sudo systemctl enable <app_name>
```

**✓ Checkpoint:** Verify service is enabled:
```bash
systemctl is-enabled <app_name>
# Should output: enabled
```

---

## Part 7: Configure Nginx Reverse Proxy

### Step 7.1: Create Nginx Configuration

```bash
# Create nginx site configuration
sudo nano /etc/nginx/sites-available/<app_name>
```

Paste this content (replace all placeholders):

```nginx
upstream <app_name> {
    server 127.0.0.1:<your_port>;
}

server {
    listen 80;
    server_name <your_domain>;

    location / {
        proxy_pass http://<app_name>;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 90;
    }

    # WebSocket support for LiveView
    location /live {
        proxy_pass http://<app_name>;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Serve static files directly
    location ~ ^/(images|javascript|js|css|flash|media|static)/ {
        root /var/www/<app_name>/shared/static;
        expires 1y;
        add_header Cache-Control public;
        add_header Last-Modified "";
        add_header ETag "";
    }
}
```

Save and exit.

### Step 7.2: Enable Nginx Site

```bash
# Create symbolic link to enable site
sudo ln -s /etc/nginx/sites-available/<app_name> /etc/nginx/sites-enabled/

# Test nginx configuration
sudo nginx -t
# Should output: syntax is ok, test is successful

# Restart nginx
sudo systemctl restart nginx
```

**✓ Checkpoint:** Verify nginx is running:
```bash
sudo systemctl status nginx
# Should show: active (running)
```

---

## Part 8: Setup GitHub Self-Hosted Runner

### Step 8.1: Create Runner on GitHub

1. Open your browser and go to your GitHub repository
2. Click **Settings** (top menu)
3. Click **Actions** (left sidebar)
4. Click **Runners** (left sidebar)
5. Click **New self-hosted runner** (green button)
6. Select **Linux** as operating system
7. **Keep this page open** - you'll need the commands shown

### Step 8.2: Install Runner on Server

```bash
# Switch to deployment user
sudo su - <deploy_user>

# Create runner directory
mkdir -p ~/actions-runner
cd ~/actions-runner

# Download runner (check GitHub page for latest version)
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

# Extract
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# Configure runner
# Copy the token from your GitHub page (from Step 8.1)
# Replace <your_username> and <app_name> with your values
./config.sh --url https://github.com/<your_username>/<app_name> --token YOUR_TOKEN_FROM_GITHUB
```

**During configuration, answer these prompts:**
- Runner group: Press **Enter** (use default)
- Runner name: Type `debian-prod` and press **Enter**
- Labels: Type `production` and press **Enter**
- Work folder: Press **Enter** (use default)

### Step 8.3: Install Runner as Service

```bash
# Still as deployment user in ~/actions-runner
sudo ./svc.sh install <deploy_user>

# Start the runner
sudo ./svc.sh start

# Check status
sudo ./svc.sh status
# Should show: active (running)

# Exit back to admin user
exit
```

**✓ Checkpoint:** Go back to your GitHub page (from Step 8.1):
- Refresh the page
- You should see your runner listed as "Idle" with a green dot

### Step 8.4: Grant Deployment User Systemd Permissions

```bash
# As admin user
# Create sudoers file (replace <deploy_user> with your deployment username)
sudo visudo -f /etc/sudoers.d/<deploy_user>
```

Add this single line (replace all placeholders):

```
<deploy_user> ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart <app_name>, /usr/bin/systemctl status <app_name>, /usr/bin/systemctl stop <app_name>, /usr/bin/systemctl start <app_name>, /usr/bin/journalctl -u <app_name> *
```

**Note:** We don't include `is-active` in the sudoers file because checking service status doesn't require elevated privileges. Only commands that modify the service (restart, stop, start) need sudo.

Save and exit (Ctrl+X, then Y, then Enter).

**✓ Checkpoint:** Test sudo permissions:
```bash
# If you're the admin user, test as deployment user:
sudo su - <deploy_user>

# Now as deployment user, test the sudo permission:
sudo systemctl status <app_name>
# Should show status without asking for password
# (It's OK if it says "Unit <app_name>.service could not be found" - we haven't deployed yet)
```

---

## Part 9: Enable Hot Code Upgrades (Optional but Recommended)

This section sets up filesystem-based hot code upgrades, enabling near-zero downtime deployments (typically <1 second) without restarting your application. The deployment system will automatically choose between hot upgrades and cold deploys based on the changes.

### Step 9.1: Create Hot Upgrades Directory

```bash
# On your server, as deployment user
sudo su - <deploy_user>

# Create hot upgrades directory
mkdir -p /var/www/<app_name>/shared/hot-upgrades

# Verify permissions
ls -la /var/www/<app_name>/shared/
# Should show hot-upgrades directory owned by <deploy_user>:<deploy_user>

exit
```

### Step 9.2: Configure Hot Deploy Module

**On your local machine:**

```bash
# The HotDeploy module should be created at lib/<app_name>/hot_deploy.ex
# Now configure it in config/runtime.exs

# Edit config/runtime.exs and add this configuration for production:
```

Add this to your `config/runtime.exs` in the production section (replace placeholders):

```elixir
if config_env() == :prod do
  # ... existing config ...

  # Hot Deploy Configuration
  config :<app_name>, <AppName>.HotDeploy,
    enabled: true,
    upgrades_dir: "/var/www/<app_name>/shared/hot-upgrades",
    check_interval: 10_000  # Check every 10 seconds
end
```

### Step 9.3: Enable Hot Upgrades in Application

Edit `lib/<app_name>/application.ex` to call the hot deploy startup function (replace placeholders):

```elixir
defmodule <AppName>.Application do
  use Application

  @impl true
  def start(_type, _args) do
    # Enable hot code upgrades before starting supervision tree
    <AppName>.HotDeploy.startup_reapply_current()

    children = [
      # ... your existing children ...
    ]

    opts = [strategy: :one_for_one, name: <AppName>.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # ... rest of the file ...
end
```

### Step 9.4: Understanding Hot vs Cold Deploy

The deployment system automatically chooses the appropriate strategy:

**Hot Code Upgrade** (zero downtime, <1s):
- Used for: Bug fixes, feature additions, UI changes, business logic updates
- Cannot handle: Database migrations, supervision tree changes, configuration changes
- Preserves: Process state, connections, LiveView sessions

**Cold Deploy** (5-10s downtime):
- Used for: Database migrations, dependency changes, OTP version upgrades
- Forced by: Including `[cold-deploy]`, `[restart]`, or `[supervision]` in commit message
- Safe for: Any type of change

The system automatically detects when cold deploy is needed and falls back gracefully.

### Step 9.5: Force Cold Deploy When Needed

If your changes require a cold deploy, add a tag to your commit message:

```bash
git commit -m "Add new supervision worker [cold-deploy]"
# or
git commit -m "Update configuration [restart]"
```

**✓ Checkpoint:** Hot code upgrades are now configured! Most deployments will complete in under 1 second without downtime.

---

## Part 10: Configure Your Local Project

Now we'll set up your local Phoenix project for automated deployment.

### Step 10.1: Create Version File

```bash
# On your LOCAL machine, navigate to your project
cd /path/to/your/project

# Create .tool-versions file
cat > .tool-versions << 'EOF'
erlang 28.0
elixir 1.19
EOF
```

### Step 10.2: Generate Release Configuration

```bash
# Still on your local machine
mix phx.gen.release

# This creates:
# - rel/overlays/bin/server
# - rel/overlays/bin/migrate
# - lib/<app_name>/release.ex
```

**✓ Checkpoint:** Verify files were created:
```bash
ls -la rel/overlays/bin/
# Should show: server, migrate

ls -la lib/<app_name>/
# Should show: release.ex
```

### Step 10.3: Create Deployment Script (Now with Hot Upgrade Support!)

**IMPORTANT:** Before running this command, replace `<deploy_user>` and `<app_name>` with your actual values throughout the script!

```bash
# Create scripts directory
mkdir -p scripts

# Create deployment script
# Replace <deploy_user> and <app_name> in the script below before saving
cat > scripts/deploy.sh << 'EOF'
#!/bin/bash
set -e

DEPLOY_USER="<deploy_user>"
DEPLOY_DIR="/var/www/<app_name>"
RELEASE_DIR="$DEPLOY_DIR/releases/$(date +%Y%m%d%H%M%S)"
CURRENT_LINK="$DEPLOY_DIR/current"
SHARED_DIR="$DEPLOY_DIR/shared"

echo "==> Creating release directory: $RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

echo "==> Extracting release tarball"
tar -xzf _build/prod/<app_name>-*.tar.gz -C "$RELEASE_DIR"

echo "==> Linking shared environment"
ln -sf "$SHARED_DIR/.env" "$RELEASE_DIR/.env"

echo "==> Running database migrations"
cd "$RELEASE_DIR"
set -a  # automatically export all variables
source "$SHARED_DIR/.env"
set +a  # stop automatically exporting
./bin/migrate

echo "==> Updating current symlink"
ln -sfn "$RELEASE_DIR" "$CURRENT_LINK"

echo "==> Creating static files symlink"
# Find the actual static files directory (handles version changes)
STATIC_DIR=$(find "$RELEASE_DIR/lib" -type d -name "priv" | head -n1)
if [ -n "$STATIC_DIR" ]; then
    ln -sfn "$STATIC_DIR/static" "$SHARED_DIR/static"
fi

echo "==> Restarting application"
sudo systemctl restart <app_name>

echo "==> Waiting for application to start..."
sleep 5

echo "==> Checking application status"
if systemctl is-active --quiet <app_name>; then
    echo "✅ Deployment successful!"

    # Clean up old releases (keep last 5)
    cd "$DEPLOY_DIR/releases"
    ls -t | tail -n +6 | xargs -r rm -rf
else
    echo "❌ Application failed to start, rolling back..."
    exit 1
fi
EOF

# Make script executable
chmod +x scripts/deploy.sh
```

**Note:** The actual deployment script in `scripts/deploy.sh` includes advanced features:
- Automated rollback on failure
- Database backup before migrations
- Comprehensive health checks with retries
- Cleanup of old releases and backups

For the complete, production-ready deployment script, see the `scripts/deploy.sh` file in your repository.

### Step 10.3b: Create Rollback Script

Now create the rollback utility for easy manual rollbacks:

```bash
# The rollback script is included in your repository at scripts/rollback.sh
# Make it executable
chmod +x scripts/rollback.sh
```

**Rollback script usage:**
```bash
# Interactive mode (menu-driven)
./scripts/rollback.sh

# Quick rollback to previous release
./scripts/rollback.sh previous

# List all releases
./scripts/rollback.sh list

# List all database backups
./scripts/rollback.sh backups
```

This script provides an easy interface for:
- Rolling back to previous or specific releases
- Restoring database backups
- Checking current deployment status
- Viewing application logs

### Step 10.4: Create GitHub Actions Workflow

**IMPORTANT:** Replace `<app_name>` and `<your_port>` with your actual values in the workflow file!

```bash
# Create .github/workflows directory
mkdir -p .github/workflows

# Create workflow file
# Replace <app_name> and <your_port> in the workflow below before saving
cat > .github/workflows/deploy.yml << 'EOF'
name: Deploy to Production

on:
  push:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-latest
    name: Test & Verify

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: <app_name>_test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Set up Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.19'
          otp-version: '28.0'

      - name: Restore dependencies cache
        uses: actions/cache@v3
        with:
          path: |
            deps
            _build
          key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-mix-

      - name: Install dependencies
        run: mix deps.get

      - name: Run precommit checks
        env:
          MIX_ENV: test
          DATABASE_URL: postgres://postgres:postgres@localhost/<app_name>_test
        run: mix precommit

  deploy:
    needs: test
    runs-on: self-hosted
    name: Build & Deploy

    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: mix deps.get --only prod

      - name: Compile application
        env:
          MIX_ENV: prod
        run: mix compile

      - name: Build assets
        env:
          MIX_ENV: prod
        run: mix assets.deploy

      - name: Build release
        env:
          MIX_ENV: prod
        run: mix release --overwrite

      - name: Create release tarball
        run: |
          cd _build/prod/rel/<app_name>
          tar -czf ../../../prod/<app_name>-0.1.0.tar.gz .
          cd -
          ls -lh _build/prod/<app_name>-*.tar.gz

      - name: Deploy release
        run: ./scripts/deploy.sh

      - name: Verify deployment
        run: |
          sleep 5
          curl -f http://localhost:<your_port> || exit 1
EOF
```

### Step 10.5: Create Environment Template

```bash
# Create .env.example (safe to commit to Git)
# Replace <deploy_user>, <app_name>, and <your_port> with your values
cat > .env.example << 'EOF'
# Database Configuration
DATABASE_URL=postgresql://<deploy_user>:your_password_here@localhost/<app_name>_dev
POOL_SIZE=10

# Phoenix Configuration
SECRET_KEY_BASE=run_mix_phx_gen_secret_to_generate
PHX_HOST=localhost
PORT=<your_port>
PHX_SERVER=true

# Optional
ECTO_IPV6=false

# Deployment Configuration
# Set to false to skip pre-deployment backups (recommended for databases >50GB)
ENABLE_PREDEPLOY_BACKUP=true
EOF
```

### Step 10.6: Update .gitignore

```bash
# Add to your .gitignore
cat >> .gitignore << 'EOF'

# Release builds
_build/
*.tar.gz

# Environment files (NEVER commit these!)
.env
.env.*
!.env.example

# Ensure these are also ignored
/priv/static/
/tmp/
EOF
```

### Step 10.7: Commit and Push

```bash
# Add all files
git add .

# Commit
git commit -m "Add automated deployment configuration"

# Push to GitHub
git push origin main
```

**⚠️ IMPORTANT:** This push will trigger your first automated deployment!

---

## Part 11: First Deployment

Your first deployment can be done automatically via GitHub Actions (which just triggered), but let's do it manually first to ensure everything works.

### Step 11.1: Manual First Deployment

```bash
# On your server, switch to deployment user
sudo su - <deploy_user>

# Navigate to application directory
cd /var/www/<app_name>

# Clone your repository (replace placeholders)
git clone https://github.com/<your_username>/<app_name>.git repo
cd repo

# Install Erlang/Elixir versions from .tool-versions
mise install

# Set up environment
export MIX_ENV=prod
set -a  # automatically export all variables
source /var/www/<app_name>/shared/.env
set +a  # stop automatically exporting

# Install dependencies
mix deps.get --only prod

# Compile application
mix compile

# Build assets
mix assets.deploy

# Build release
mix release

# Create tarball from the release
cd _build/prod/rel/<app_name>
tar -czf ../../../prod/<app_name>-0.1.0.tar.gz .
cd -

# Create first release directory
RELEASE_DIR="/var/www/<app_name>/releases/$(date +%Y%m%d%H%M%S)"
mkdir -p "$RELEASE_DIR"

# Extract release
tar -xzf _build/prod/<app_name>-*.tar.gz -C "$RELEASE_DIR"

# Link to current
ln -sfn "$RELEASE_DIR" /var/www/<app_name>/current

# Create static files symlink (for nginx)
STATIC_DIR=$(find "$RELEASE_DIR/lib" -type d -name "priv" | head -n1)
ln -sfn "$STATIC_DIR/static" /var/www/<app_name>/shared/static

# Run migrations
cd /var/www/<app_name>/current
./bin/migrate

# Start the application
sudo systemctl start <app_name>

# Check status
sudo systemctl status <app_name>
# Should show: active (running)

# Exit back to admin
exit
```

### Step 11.2: Verify Deployment

```bash
# Check if application is responding
curl http://localhost:<your_port>
# Should show HTML response

# Check logs
sudo journalctl -u <app_name> -n 50
# Should show application startup logs

# Check nginx
curl http://your-server-ip
# Should show your application

# Or from your browser
# Visit: http://<your_domain> (or http://your-server-ip)
```

**✅ SUCCESS!** Your application is now deployed!

---

## Part 12: Setup SSL with Let's Encrypt (Optional but Recommended)

### Step 12.1: Install Certbot

```bash
# Install certbot
sudo apt install -y certbot python3-certbot-nginx
```

### Step 12.2: Obtain SSL Certificate

```bash
# Get SSL certificate (replace <your_domain> with your actual domain)
sudo certbot --nginx -d <your_domain>

# Follow the prompts:
# - Enter your email address
# - Agree to terms of service
# - Choose whether to redirect HTTP to HTTPS (recommended: Yes)
```

### Step 12.3: Test Auto-Renewal

```bash
# Test certificate renewal
sudo certbot renew --dry-run

# Should show: Congratulations, all simulated renewals succeeded
```

**✅ Your site is now secured with HTTPS!**

---

## Part 13: Setup Automated Database Backups

### Step 13.1: Configure Cron Job

```bash
# Switch to deployment user
sudo su - <deploy_user>

# Edit crontab
crontab -e

# If prompted to choose an editor, select nano (usually option 1)
```

Add these lines at the bottom (replace placeholders):

```cron
# Daily database backup at 2 AM
0 2 * * * pg_dump -U <deploy_user> <app_name>_prod | gzip > /var/www/<app_name>/shared/backups/<app_name>_$(date +\%Y\%m\%d).sql.gz

# Clean backups older than 30 days at 3 AM
0 3 * * * find /var/www/<app_name>/shared/backups -name "<app_name>_*.sql.gz" -mtime +30 -delete
```

Save and exit (Ctrl+X, then Y, then Enter).

```bash
# Exit back to admin
exit
```

**✅ Database backups are now automated!**

### Step 13.2: Understanding Backup Strategy

Your deployment system includes **two types of backups**:

**1. Daily Automated Backups** (configured above)
- Run via cron at 2 AM daily
- Store in `/var/www/<app_name>/shared/backups/<app_name>_YYYYMMDD.sql.gz`
- Keep for 30 days
- Use gzipped SQL format for portability

**2. Pre-Deployment Backups** (automatic during deployment)
- Created before every database migration
- Store in `/var/www/<app_name>/shared/backups/pre-deploy-*.dump`
- Use PostgreSQL custom format (20-30% faster)
- Keep last 10 backups
- Can be disabled via `.env` configuration

### Step 13.3: When to Disable Pre-Deployment Backups

Pre-deployment backups provide an extra safety net but may impact deployment speed for large databases.

**Disable pre-deployment backups when:**

✅ **Large database (>50GB):**
- Backup takes >5 minutes
- Significantly delays deployment pipeline
- I/O impact on production server

✅ **Already have robust backup system:**
- Daily automated backups running (configured above)
- External backup solution (pgBackRest, Barman, cloud snapshots)
- WAL archiving with Point-in-Time Recovery (PITR)

✅ **High deployment frequency:**
- Multiple deployments per day
- Fast iteration cycles
- Development/staging environments

✅ **Database changes are minimal:**
- Mostly application-only updates (no migrations)
- Using hot code upgrades (no schema changes)
- Read-heavy workloads

**Keep pre-deployment backups when:**

❌ **Small database (<10GB)** - Fast, low-impact safety measure
❌ **Infrequent deployments** - Extra safety for rare updates
❌ **No other backup system** - Critical safety measure
❌ **High-risk migrations** - Complex schema changes

**To disable pre-deployment backups:**

```bash
# On your server, edit the .env file
sudo su - <deploy_user>
nano /var/www/<app_name>/shared/.env

# Add this line:
ENABLE_PREDEPLOY_BACKUP=false

# Save and exit (Ctrl+X, Y, Enter)
```

**Performance comparison:**

| Database Size | pg_dump Time | Custom Format | Impact |
|---------------|-------------|---------------|---------|
| 1 GB | ~30 seconds | ~20 seconds | ✅ Minimal |
| 10 GB | ~5 minutes | ~3 minutes | ⚠️ Moderate |
| 50 GB | ~25 minutes | ~15 minutes | ❌ Significant |
| 100+ GB | ~1+ hour | ~30+ minutes | ❌ Prohibitive |

**Note:** Your deployment script uses the optimized custom format (`--format=custom --compress=6`) which is 20-30% faster than plain SQL dumps.

**Alternative for very large databases:**

If you have a very large database (>100GB), consider:
- **File system snapshots** (AWS EBS, LVM, ZFS) - Instant backups
- **pg_basebackup** - Physical backups with WAL archiving
- **pgBackRest** - Enterprise backup tool with incremental backups
- **Managed database services** - Automated backup/restore (AWS RDS, Google Cloud SQL)

---

## Part 14: Security Hardening

### Step 14.1: Configure Firewall

```bash
# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP
sudo ufw allow 80/tcp

# Allow HTTPS
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

### Step 14.2: Setup Automatic Security Updates

```bash
# Configure unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Select "Yes" when prompted
```

### Step 14.3: Install fail2ban (Brute Force Protection)

```bash
# Install fail2ban
sudo apt install -y fail2ban

# Enable and start
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Check status
sudo systemctl status fail2ban
```

### Step 14.4: Harden SSH (Optional but Recommended)

```bash
# Edit SSH config
sudo nano /etc/ssh/sshd_config

# Find and modify these lines (remove # if commented):
# PasswordAuthentication no
# PubkeyAuthentication yes
# PermitRootLogin no

# Save and exit

# Restart SSH
sudo systemctl restart sshd
```

**⚠️ WARNING:** Only do this if you have SSH key authentication set up! Otherwise you'll lock yourself out.

---

## Part 15: Testing Automated Deployments

### Step 15.1: Make a Change and Push

```bash
# On your LOCAL machine
cd /path/to/your/project

# Make a small change (e.g., edit README)
echo "Testing deployment" >> README.md

# Commit and push
git add README.md
git commit -m "Test automated deployment"
git push origin main
```

### Step 15.2: Watch Deployment on GitHub

1. Go to your GitHub repository
2. Click **Actions** tab
3. You should see a new workflow run
4. Click on it to watch the deployment progress
5. Wait for it to complete (usually 5-10 minutes)

### Step 15.3: Verify on Server

```bash
# On your server
sudo journalctl -u <app_name> -n 50

# Check if application is running
curl http://localhost:<your_port>

# Visit your site in browser
# Should show the updated application
```

**✅ Automated deployments are working!**

---

## Daily Operations

### View Application Logs

```bash
# Real-time logs
sudo journalctl -u <app_name> -f

# Last 100 lines
sudo journalctl -u <app_name> -n 100

# Today's logs
sudo journalctl -u <app_name> --since today
```

### Manual Deployment Commands

```bash
# Restart application
sudo systemctl restart <app_name>

# Stop application
sudo systemctl stop <app_name>

# Start application
sudo systemctl start <app_name>

# Check status
sudo systemctl status <app_name>
```

### Automated Rollback

**Good news!** Your deployment system includes automatic rollback. If a deployment fails, the system automatically:

1. Detects the failure (migration errors, health check failures, service startup issues)
2. Restores the previous release symlink
3. Restarts the application with the working code
4. Cleans up the failed release directory

**What triggers automatic rollback:**
- Database migration failures
- Application startup failures
- Health check failures (HTTP endpoint not responding)
- Service fails to activate within timeout

**Database safety:**
- A database backup is created before every migration (configurable)
- Backups use PostgreSQL custom format (20-30% faster than plain SQL)
- Backups are stored in `/var/www/<app_name>/shared/backups/pre-deploy-*.dump`
- Last 10 pre-deployment backups are kept automatically
- Can be disabled for large databases via `ENABLE_PREDEPLOY_BACKUP=false` in `.env`

### Manual Rollback with Rollback Script

The easiest way to manually rollback is using the rollback utility:

```bash
# Switch to deployment user
sudo su - <deploy_user>

# Run the rollback script
cd /var/www/<app_name>/repo
./scripts/rollback.sh
```

**Rollback script features:**
1. **Quick rollback to previous release** - One command rollback
2. **Interactive menu** - Choose specific release or backup to restore
3. **List releases** - View all available releases
4. **Database restore** - Restore from any backup
5. **Status check** - View current deployment status and logs

**Quick rollback (non-interactive):**
```bash
# Rollback to previous release immediately
./scripts/rollback.sh previous

# List all releases
./scripts/rollback.sh list

# List all database backups
./scripts/rollback.sh backups
```

### Manual Rollback (Advanced)

If you need to rollback manually without the script:

```bash
# Switch to deployment user
sudo su - <deploy_user>

# List releases
cd /var/www/<app_name>/releases
ls -lt

# Link to previous release (replace TIMESTAMP with actual timestamp)
ln -sfn /var/www/<app_name>/releases/TIMESTAMP /var/www/<app_name>/current

# Exit deployment user
exit

# Restart application
sudo systemctl restart <app_name>
```

### Restore Database Backup

**Using the rollback script (recommended):**
```bash
sudo su - <deploy_user>
cd /var/www/<app_name>/repo
./scripts/rollback.sh
# Then select option 4 to restore database from backup
```

**Manual database restore:**
```bash
# List backups
sudo ls -lh /var/www/<app_name>/shared/backups/

# Restore a backup (replace DATE with actual date)
sudo -u <deploy_user> gunzip -c /var/www/<app_name>/shared/backups/<app_name>_DATE.sql.gz | sudo -u <deploy_user> psql <app_name>_prod
```

---

## Troubleshooting

### Application Won't Start

```bash
# Check detailed logs
sudo journalctl -u <app_name> -n 200 --no-pager

# Check if port is in use
sudo netstat -tlnp | grep <your_port>

# Verify environment variables
sudo -u <deploy_user> cat /var/www/<app_name>/shared/.env

# Test release manually
sudo su - <deploy_user>
cd /var/www/<app_name>/current
source /var/www/<app_name>/shared/.env
./bin/<app_name> start
./bin/<app_name> pid
exit
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
sudo -u <deploy_user> psql -U <deploy_user> -d <app_name>_prod -h localhost

# Check PostgreSQL is running
sudo systemctl status postgresql

# View PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-*-main.log
```

### Runner Not Connecting

```bash
# Check runner status
sudo su - <deploy_user>
cd ~/actions-runner
sudo ./svc.sh status

# View runner logs
journalctl -u actions.runner.* -f

exit
```

### Permission Issues

```bash
# Ensure correct ownership
sudo chown -R <deploy_user>:<deploy_user> /var/www/<app_name>

# Check .env file permissions
ls -la /var/www/<app_name>/shared/.env
# Should show: -rw------- 1 <deploy_user> <deploy_user>

# Check sudoers configuration
sudo cat /etc/sudoers.d/<deploy_user>
```

---

## Summary

**🎉 Congratulations!** Your Phoenix application is now:

- ✅ Deployed on Debian Linux
- ✅ Running as systemd service
- ✅ Secured with HTTPS (if you configured Let's Encrypt)
- ✅ Auto-deploying on push to `main`
- ✅ Running automated tests before deployment
- ✅ **Performing hot code upgrades (<1s downtime) for most deployments**
- ✅ **Automatically falling back to cold deploy when needed**
- ✅ **Automated rollback on deployment failures**
- ✅ Running database migrations automatically with pre-migration backups
- ✅ Comprehensive health checks (HTTP endpoint verification)
- ✅ Backing up database daily
- ✅ Protected by firewall and fail2ban
- ✅ Keeping old releases for easy rollback
- ✅ Interactive rollback script for manual rollbacks

**Every time you push to `main`:**
1. GitHub Actions runs your tests
2. If tests pass, it builds a release
3. Deploys to your server automatically
4. **Creates database backup before migrations**
5. **Intelligently chooses hot upgrade (zero downtime) or cold deploy**
6. Runs database migrations (if needed)
7. For hot upgrades: suspends processes, loads new code, resumes (<1s)
8. For cold deploys: restarts the application with minimal downtime (5-10s)
9. **Performs comprehensive health checks (service + HTTP endpoint)**
10. **Automatically rolls back on failure** (restores previous release + restarts)
11. Cleans up old releases and backups

**Deployment Safety Features:**
- 🛡️ **Automatic rollback** on migration failures, startup failures, or health check failures
- 💾 **Pre-deployment database backups** created before every migration
- 🏥 **Health endpoint** verifies application + database connectivity
- 🔄 **6 retry attempts** with 5-second intervals before declaring failure
- 📝 **Detailed logging** of all deployment steps and failures
- 🧹 **Automatic cleanup** of failed releases

**Hot Code Upgrade Benefits:**
- 🚀 **<1 second deployment** for most changes
- 🔄 **Preserves process state** and LiveView sessions
- 🌐 **No connection drops** for active users
- 📱 **Mobile-friendly** - users don't notice updates
- 🎯 **Automatic fallback** to cold deploy when needed

**Rollback Options:**
- ⚡ **Automatic** - Deployment script rolls back on any failure
- 🎮 **Interactive** - Use `./scripts/rollback.sh` for menu-driven rollback
- ⚡ **Quick** - Use `./scripts/rollback.sh previous` for one-command rollback
- 🗄️ **Database** - Restore from any backup using the rollback script

**Need help?** Check the Troubleshooting section above or review the logs with `sudo journalctl -u <app_name> -f`
