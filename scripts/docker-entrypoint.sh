#!/bin/bash
set -e

# DrClaw reads config from ~/.drclaw/config.json (hardcoded in get_data_dir())
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

# Only create default config if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file not found, creating default config at $CONFIG_FILE"
    cat > "$CONFIG_FILE" << EOF
{
  "provider": {
    "api_key": "",
    "api_base": "",
    "model": "anthropic/claude-sonnet-4-5"
  },
  "daemon": {
    "frontends": ["web"],
    "verbose_chat": true,
    "show_tool_calls": true,
    "web_in_docker": true
  },
  "feishu": {
    "app_id": "",
    "app_secret": "",
    "encrypt_key": "",
    "verification_token": ""
  },
  "data_dir": "$DATA_DIR"
}
EOF
    chown drclaw:drclaw "$CONFIG_FILE" 2>/dev/null || true
else
    echo "Config file already exists at $CONFIG_FILE, preserving existing configuration"
fi

# Update config with environment variables if provided
# Use jq to merge environment variables into existing config
if command -v jq &> /dev/null; then
    # Update provider settings if environment variables are set
    [ -n "$DRCLAW_PROVIDER_API_KEY" ] && \
        jq --arg v "$DRCLAW_PROVIDER_API_KEY" '.provider.api_key = $v' "$CONFIG_FILE" > /tmp/config.json && mv /tmp/config.json "$CONFIG_FILE"
    
    [ -n "$DRCLAW_PROVIDER_API_BASE" ] && \
        jq --arg v "$DRCLAW_PROVIDER_API_BASE" '.provider.api_base = $v' "$CONFIG_FILE" > /tmp/config.json && mv /tmp/config.json "$CONFIG_FILE"
    
    [ -n "$DRCLAW_PROVIDER_MODEL" ] && \
        jq --arg v "$DRCLAW_PROVIDER_MODEL" '.provider.model = $v' "$CONFIG_FILE" > /tmp/config.json && mv /tmp/config.json "$CONFIG_FILE"
    
    # Update feishu settings if environment variables are set
    [ -n "$DRCLAW_FEISHU_APP_ID" ] && \
        jq --arg v "$DRCLAW_FEISHU_APP_ID" '.feishu.app_id = $v' "$CONFIG_FILE" > /tmp/config.json && mv /tmp/config.json "$CONFIG_FILE"
    
    [ -n "$DRCLAW_FEISHU_APP_SECRET" ] && \
        jq --arg v "$DRCLAW_FEISHU_APP_SECRET" '.feishu.app_secret = $v' "$CONFIG_FILE" > /tmp/config.json && mv /tmp/config.json "$CONFIG_FILE"
    
    [ -n "$DRCLAW_FEISHU_ENCRYPT_KEY" ] && \
        jq --arg v "$DRCLAW_FEISHU_ENCRYPT_KEY" '.feishu.encrypt_key = $v' "$CONFIG_FILE" > /tmp/config.json && mv /tmp/config.json "$CONFIG_FILE"
    
    [ -n "$DRCLAW_FEISHU_VERIFICATION_TOKEN" ] && \
        jq --arg v "$DRCLAW_FEISHU_VERIFICATION_TOKEN" '.feishu.verification_token = $v' "$CONFIG_FILE" > /tmp/config.json && mv /tmp/config.json "$CONFIG_FILE"
    
    echo "Config updated with environment variables"
else
    echo "jq not found, skipping environment variable updates"
fi

echo "Starting DrClaw daemon with web frontend on ${WEB_HOST}:${WEB_PORT}"

# Run the daemon
cd /app
exec drclaw daemon -f web
