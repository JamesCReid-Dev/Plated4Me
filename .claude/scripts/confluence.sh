#!/bin/bash
# confluence.sh — CLI wrapper for Confluence REST API operations.
# Usage: ./confluence.sh <command> [args...]
#
# Commands:
#   page <page_id>              Fetch page content (full JSON)
#   page-content <page_id>      Fetch just the page body/storage value
#   search <query>              Search pages by text match in space
#   space                       Get space details for CONFLUENCE_SPACE_KEY
#   children <page_id>          List child pages of a page

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/atlassian-lib.sh"

# Confluence uses /wiki/rest/api/ prefix (not just /rest/api/)
CONFLUENCE_API="wiki/rest/api"

cmd="${1:-help}"
shift || true

case "$cmd" in
  page)
    id="$1"
    atlassian_get "${CONFLUENCE_API}/content/${id}"
    ;;

  page-content)
    id="$1"
    atlassian_get "${CONFLUENCE_API}/content/${id}/body/storage"
    ;;

  search)
    query="$*"
    encoded=$(printf '%s' "$query" | python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.stdin.read()), end="")')
    atlassian_get "${CONFLUENCE_API}/content" "spaceKey=${CONFLUENCE_SPACE_KEY}&searchAll=true&expand=page.title&page.title=${encoded}"
    ;;

  space)
    key="${1:-$CONFLUENCE_SPACE_KEY}"
    atlassian_get "${CONFLUENCE_API}/space/${key}"
    ;;

  children)
    id="$1"
    atlassian_get "${CONFLUENCE_API}/content/${id}/children/page"
    ;;

  help|--help|-h)
    echo "Usage: $0 <command> [args...]"
    echo ""
    echo "Commands:"
    echo "  page <page_id>              Fetch page content (full JSON)"
    echo "  page-content <page_id>      Fetch just the page body/storage value"
    echo "  search <query>              Search pages by text match in space"
    echo "  space [space_key]           Get space details for CONFLUENCE_SPACE_KEY"
    echo "  children <page_id>          List child pages of a page"
    ;;

  *)
    echo "ERROR: Unknown command '$cmd'. Run '$0 help' for usage." >&2
    exit 1
    ;;
esac
