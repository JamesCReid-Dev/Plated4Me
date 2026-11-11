#!/bin/bash
# jira.sh — CLI wrapper for Jira REST API operations.
# Usage: ./jira.sh <command> [args...]
#
# Commands:
#   get <issue_key>              Fetch issue details (full JSON)
#   search <jql_query>           Search issues by JQL
#   transitions <issue_key>      List available transitions for an issue
#   transition <key> <id>        Transition issue to new status
#   assign <key> <user>          Assign issue to user (name/email/accountId)
#   comment <key> <body>         Add comment to issue
#   fields <key> [field...]      Print specific field values from an issue
#   me                           Show authenticated user info

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/atlassian-lib.sh"

cmd="${1:-help}"
shift || true

case "$cmd" in
  get)
    key="$1"
    atlassian_get "rest/api/2/issue/${key}"
    ;;

  search)
    jql="$*"
    atlassian_search_jql "$jql"
    ;;

  transitions)
    key="$1"
    atlassian_get "rest/api/2/issue/${key}/transitions"
    ;;

  transition)
    key="$1"; id="$2"
    atlassian_transition "$key" "$id"
    ;;

  assign)
    key="$1"; user="$2"
    atlassian_assign_issue "$key" "$user"
    ;;

  comment)
    key="$1"; shift
    body="$*"
    # Escape double quotes and newlines for JSON embedding
    escaped_body=$(printf '%s' "$body" | sed 's/"/\\"/g; s/$/\\n/g' | sed '$ s/\\n$//')
    atlassian_add_comment "$key" "$escaped_body"
    ;;

  fields)
    key="$1"; shift
    # Fetch full issue, then extract requested fields using python3 for clean output
    result=$(atlassian_get "rest/api/2/issue/${key}")
    if [[ $# -eq 0 ]]; then
      echo "$result" | python3 -m json.tool
    else
      export ATLASSIAN_ISSUE_JSON="$result"
      export ATLASSIAN_FIELDS="$*"
      python3 <<'PYEOF'
import os, json

data = json.loads(os.environ["ATLASSIAN_ISSUE_JSON"])
fields_data = data.get("fields", {})
field_names = os.environ["ATLASSIAN_FIELDS"].split()

def fmt(val):
    if val is None or val == "":
        return "<not set>"
    if isinstance(val, str):
        return val
    if isinstance(val, dict):
        n = val.get("name") or val.get("displayName") or ""
        k = val.get("key", "")
        if k and n:
            return f"{k} ({n})"
        elif k:
            return k
        elif n:
            return n
        items = list(val.items())[:3]
        return str(items)
    if isinstance(val, list):
        if len(val) == 0:
            return "[]"
        names = []
        for x in val[:5]:
            if isinstance(x, dict):
                names.append(x.get("name", x.get("displayName", "")))
            else:
                names.append(str(x))
        s = ", ".join(names)
        if len(val) > 5:
            s += f" (and {len(val)-5} more)"
        return s
    if isinstance(val, (int, float, bool)):
        return str(val)
    return str(val)[:200]

for fname in field_names:
    val = fields_data.get(fname)
    print(f"{fname}: {fmt(val)}")
PYEOF
      unset ATLASSIAN_ISSUE_JSON ATLASSIAN_FIELDS
    fi
    ;;

  me)
    atlassian_get "rest/api/2/myself"
    ;;

  help|--help|-h)
    echo "Usage: $0 <command> [args...]"
    echo ""
    echo "Commands:"
    echo "  get <issue_key>              Fetch issue details (full JSON)"
    echo "  search <jql_query>           Search issues by JQL"
    echo "  transitions <issue_key>      List available transitions for an issue"
    echo "  transition <key> <id>        Transition issue to new status"
    echo "  assign <key> <user>          Assign issue to user (name/email/accountId)"
    echo "  comment <key> <body>         Add comment to issue"
    echo "  fields <key> [field...]      Print specific field values from an issue"
    echo "  me                           Show authenticated user info"
    ;;

  *)
    echo "ERROR: Unknown command '$cmd'. Run '$0 help' for usage." >&2
    exit 1
    ;;
esac
