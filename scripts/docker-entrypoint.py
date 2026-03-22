#!/usr/bin/env python3
"""
DrClaw Docker Entrypoint

Configures DrClaw for Docker environment and starts the daemon.
"""

import os
import sys
import json
import subprocess

# Add app directory to Python path
sys.path.insert(0, '/app')

# Configuration from environment
WEB_PORT = int(os.environ.get("DRCLAW_WEB_PORT", "8081"))
WEB_HOST = os.environ.get("DRCLAW_WEB_HOST", "0.0.0.0")
DATA_DIR = os.environ.get("DRCLAW_DATA_DIR", "/root/.drclaw")

# Ensure data directory exists
os.makedirs(DATA_DIR, exist_ok=True)
config_file = os.path.join(DATA_DIR, "config.json")

config = {
    "provider": {
        "api_key": os.environ.get("DRCLAW_PROVIDER_API_KEY", ""),
        "api_base": os.environ.get("DRCLAW_PROVIDER_API_BASE", ""),
        "model": os.environ.get("DRCLAW_PROVIDER_MODEL", "anthropic/claude-sonnet-4-5")
    },
    "daemon": {
        "frontends": ["web"],
        "verbose_chat": True,
        "show_tool_calls": True
    },
    "feishu": {
        "app_id": os.environ.get("DRCLAW_FEISHU_APP_ID", ""),
        "app_secret": os.environ.get("DRCLAW_FEISHU_APP_SECRET", ""),
        "encrypt_key": os.environ.get("DRCLAW_FEISHU_ENCRYPT_KEY", ""),
        "verification_token": os.environ.get("DRCLAW_FEISHU_VERIFICATION_TOKEN", "")
    },
    "data_dir": DATA_DIR
}

# Always write config
with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)
print(f"Config written to {config_file}")

# Run the daemon with -f web to explicitly specify frontend
print(f"Starting DrClaw daemon with web frontend on {WEB_HOST}:{WEB_PORT}")

# Patch WebAdapter default host/port before importing drclaw
import drclaw.frontends.web.adapter as web_adapter_module
from drclaw.frontends.web.adapter import WebAdapter
# Save original __init__
_original_init = WebAdapter.__init__

def _patched_init(self, host: str = WEB_HOST, port: int = WEB_PORT):
    _original_init(self, host=host, port=port)

WebAdapter.__init__ = _patched_init

# Use typer to run directly
from drclaw.cli import app as cli_app
import typer

# Clear sys.argv to avoid Typer issues
sys.argv = ["drclaw", "daemon", "-f", "web"]

# Run typer
if __name__ == "__main__":
    from drclaw.cli.app import app
    app()
