#!/bin/bash
set -euo pipefail

# Source credentials from the local env file
env_file="$(dirname "$0")/.atlassian.env"
if [ ! -f "$env_file" ]; then
  echo "ERROR: $env_file not found" >&2
  exit 1
fi
source "$env_file"

# Pass config as CLI args (more reliable than env vars with Claude Code MCP transport)
exec atlassian-mcp \
  --base-url "$ATLASSIAN_BASE_URL" \
  --token "$ATLASSIAN_API_TOKEN" \
  --username "$ATLASSIAN_USERNAME"
