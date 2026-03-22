#!/bin/bash
set -e

# DrClaw reads config from ~/.drclaw/config.json (hardcoded in get_data_dir())
# We must write to the correct location
DRCLAW_HOME="/home/drclaw"
CONFIG_DIR="$DRCLAW_HOME/.drclaw"
CONFIG_FILE="$CONFIG_DIR/config.json"

# Configuration from environment
WEB_PORT="${DRCLAW_WEB_PORT:-8081}"
WEB_HOST="${DRCLAW_WEB_HOST:-127.0.0.1}"
DATA_DIR="${DRCLAW_DATA_DIR:-$DRCLAW_HOME/.drclaw}"

# Ensure directories exist with proper permissions
mkdir -p "$CONFIG_DIR"
mkdir -p "$DATA_DIR"
chown -R drclaw:drclaw "$DRCLAW_HOME" 2>/dev/null || true

# Generate config file
cat > "$CONFIG_FILE" << EOF
{
  "provider": {
    "api_key": "${DRCLAW_PROVIDER_API_KEY:-}",
    "api_base": "${DRCLAW_PROVIDER_API_BASE:-}",
    "model": "${DRCLAW_PROVIDER_MODEL:-anthropic/claude-sonnet-4-5}"
  },
  "daemon": {
    "frontends": ["web"],
    "verbose_chat": true,
    "show_tool_calls": true,
    "web_in_docker": true
  },
  "feishu": {
    "app_id": "${DRCLAW_FEISHU_APP_ID:-}",
    "app_secret": "${DRCLAW_FEISHU_APP_SECRET:-}",
    "encrypt_key": "${DRCLAW_FEISHU_ENCRYPT_KEY:-}",
    "verification_token": "${DRCLAW_FEISHU_VERIFICATION_TOKEN:-}"
  },
  "data_dir": "$DATA_DIR"
}
EOF

chown drclaw:drclaw "$CONFIG_FILE" 2>/dev/null || true

echo "Config written to $CONFIG_FILE"
echo "Starting DrClaw daemon with web frontend on ${WEB_HOST}:${WEB_PORT}"

# Run the daemon
cd /app
exec drclaw daemon -f web
