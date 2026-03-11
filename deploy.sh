#!/usr/bin/env bash
# =============================================================
# Postiz – Hostinger VPS Deployment Script
# Usage: bash deploy.sh
# =============================================================
set -euo pipefail

REPO_URL="https://github.com/Captainjacksparrow93/Postiz.git"
APP_DIR="/opt/postiz"

echo "=============================="
echo "  Postiz VPS Deployment"
echo "=============================="

# ── 1. Install Docker if missing ──────────────────────────────
if ! command -v docker &>/dev/null; then
  echo "[1/5] Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker
  systemctl start docker
else
  echo "[1/5] Docker already installed – skipping."
fi

# ── 2. Clone or pull the repo ─────────────────────────────────
if [ -d "$APP_DIR/.git" ]; then
  echo "[2/5] Pulling latest code..."
  git -C "$APP_DIR" pull
else
  echo "[2/5] Cloning repo..."
  git clone "$REPO_URL" "$APP_DIR"
fi

cd "$APP_DIR"

# ── 3. Create .env if it does not yet exist ───────────────────
if [ ! -f ".env" ]; then
  echo ""
  echo "[3/5] .env not found – creating from .env.example"
  cp .env.example .env
  echo ""
  echo "  !! ACTION REQUIRED !!"
  echo "  Edit $APP_DIR/.env before continuing:"
  echo "    nano $APP_DIR/.env"
  echo ""
  echo "  Minimum values to set:"
  echo "    MAIN_URL            – http://72.62.248.38:4007  (already defaulted in docker-compose)"
  echo "    FRONTEND_URL        – http://72.62.248.38:4007  (already defaulted in docker-compose)"
  echo "    NEXT_PUBLIC_BACKEND_URL – http://72.62.248.38:4007/api (already defaulted)"
  echo "    JWT_SECRET          – long random string (REQUIRED)"
  echo "    POSTGRES_PASSWORD   – secure DB password (REQUIRED)"
  echo ""
  echo "  After editing, re-run:  bash $APP_DIR/deploy.sh"
  exit 0
else
  echo "[3/5] .env found – using existing file."
fi

# ── 4. Pull latest Docker images ─────────────────────────────
echo "[4/5] Pulling Docker images..."
docker compose pull

# ── 5. Start / restart services ──────────────────────────────
echo "[5/5] Starting services..."
docker compose up -d --remove-orphans

echo ""
echo "=============================="
echo "  Deployment complete!"
echo "  App should be available at: $(grep '^MAIN_URL' .env | cut -d= -f2 | tr -d \"'\" || echo 'your MAIN_URL')"
echo "=============================="
