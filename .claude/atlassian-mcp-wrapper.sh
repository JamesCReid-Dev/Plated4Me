#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/.atlassian.env"
exec atlassian-mcp
