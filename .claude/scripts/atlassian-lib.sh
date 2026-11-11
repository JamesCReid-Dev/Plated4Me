#!/bin/bash
# Shared library for Atlassian REST API calls.
# Sourced by individual scripts; provides auth, HTTP helpers, and error handling.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Look for .atlassian.env in the scripts dir first, then parent dir (.claude/)
if [ -f "$SCRIPT_DIR/.atlassian.env" ]; then
  ENV_FILE="$SCRIPT_DIR/.atlassian.env"
elif [ -f "$(dirname "$SCRIPT_DIR")/.atlassian.env" ]; then
  ENV_FILE="$(dirname "$SCRIPT_DIR")/.atlassian.env"
else
  echo "ERROR: .atlassian.env not found in $SCRIPT_DIR or parent directory" >&2
  exit 1
fi
source "$ENV_FILE"

# Also load project variables from .bmad.secrets.env (check multiple locations)
for _candidate in \
  "$(dirname "$SCRIPT_DIR")/.bmad.secrets.env" \
  "$(dirname "$(dirname "$SCRIPT_DIR")")/.bmad.secrets.env"; do
  if [ -f "$_candidate" ]; then
    source "$_candidate"
    break
  fi
done
unset _candidate

# ── Auth helpers ──────────────────────────────────────────────
_AUTH_ARGS=("-u" "${ATLASSIAN_USERNAME}:${ATLASSIAN_API_TOKEN}")
_HEADERS=(
  "Accept: application/json"
  "Content-Type: application/json"
)

# ── HTTP helpers ──────────────────────────────────────────────
# atlassian_get <path> [query_string]
#   GET request, prints raw JSON to stdout.
#   query_string: optional URL-encoded query params (e.g., "maxResults=10&expand=fields")
atlassian_get() {
  local path="$1"
  local query="${2:-}"
  local url="${ATLASSIAN_BASE_URL}/${path}"
  if [[ -n "$query" ]]; then
    url="${url}?${query}"
  fi
  curl -sS "${_AUTH_ARGS[@]}" \
       -H "${_HEADERS[0]}" \
       "$url" 2>/dev/null
}

# atlassian_get_jql <path> <jql_param_name> <jql_value> [other_query_params]
#   GET request with a JQL parameter that needs URL-encoding.
atlassian_get_jql() {
  local path="$1"
  local jql_key="${2:-jql}"
  local jql_val="$3"
  local extra="${4:-}"

  # Build base URL with optional extra query params
  local url="${ATLASSIAN_BASE_URL}/${path}"
  if [[ -n "$extra" ]]; then
    url="${url}?${extra}&${jql_key}="
  else
    url="${url}?${jql_key}="
  fi

  # URL-encode the JQL value and append
  local encoded
  encoded=$(printf '%s' "$jql_val" | python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.stdin.read()), end="")')
  url="${url}${encoded}"

  curl -sS "${_AUTH_ARGS[@]}" \
       -H "${_HEADERS[0]}" \
       "$url" 2>/dev/null
}

# atlassian_post <path> <json_body>
#   POST request, prints raw JSON to stdout.
atlassian_post() {
  local path="$1"
  local body="$2"
  curl -sS "${_AUTH_ARGS[@]}" \
       -H "${_HEADERS[0]}" \
       -H "${_HEADERS[1]}" \
       -X POST \
       -d "$body" \
       "${ATLASSIAN_BASE_URL}/${path}" 2>/dev/null
}

# atlassian_put <path> <json_body>
#   PUT request, prints raw JSON to stdout.
atlassian_put() {
  local path="$1"
  local body="$2"
  curl -sS "${_AUTH_ARGS[@]}" \
       -H "${_HEADERS[0]}" \
       -H "${_HEADERS[1]}" \
       -X PUT \
       -d "$body" \
       "${ATLASSIAN_BASE_URL}/${path}" 2>/dev/null
}

# atlassian_patch <path> <json_body>
#   PATCH request, prints raw JSON to stdout.
atlassian_patch() {
  local path="$1"
  local body="$2"
  curl -sS "${_AUTH_ARGS[@]}" \
       -H "${_HEADERS[0]}" \
       -H "${_HEADERS[1]}" \
       -X PATCH \
       -d "$body" \
       "${ATLASSIAN_BASE_URL}/${path}" 2>/dev/null
}

# atlassian_delete <path>
#   DELETE request, prints raw JSON to stdout.
atlassian_delete() {
  local path="$1"
  curl -sS "${_AUTH_ARGS[@]}" \
       -H "${_HEADERS[0]}" \
       -X DELETE \
       "${ATLASSIAN_BASE_URL}/${path}" 2>/dev/null
}

# atlassian_search_jql <jql_query> [fields] [limit]
#   Search issues using JQL (v3 API — v2 search was deprecated by Atlassian).
#   Returns matching issues as JSON object with "issues" array.
atlassian_search_jql() {
  local jql="$1"
  local fields="${2:-summary,status,assignee,creator,labels,description,priority,issuetype}"
  local limit="${3:-50}"

  local extra="maxResults=${limit}&fields=${fields}"
  atlassian_get_jql "rest/api/3/search/jql" "jql" "$jql" "$extra"
}

# atlassian_transition <issue_key> <transition_id_or_name>
#   Transition an issue to a new status. Returns the transition result.
atlassian_transition() {
  local issue_key="$1"
  local transition_id="$2"
  atlassian_post "rest/api/2/issue/${issue_key}/transitions" \
    "{\"transition\": {\"id\": \"${transition_id}\"}}"
}

# atlassian_add_comment <issue_key> <comment_body>
#   Add a comment to an issue. Supports plain text and basic Jira markup.
atlassian_add_comment() {
  local issue_key="$1"
  local body="$2"
  atlassian_post "rest/api/2/issue/${issue_key}/comment" \
    "{\"body\": \"${body}\"}"
}

# atlassian_assign_issue <issue_key> <account_id_or_name>
#   Assign an issue to a user. Accepts accountId, username, or email.
atlassian_assign_issue() {
  local issue_key="$1"
  local assignee="$2"
  atlassian_patch "rest/api/2/issue/${issue_key}" \
    "{\"fields\": {\"assignee\": {\"name\": \"${assignee}\"}}}"
}

# atlassian_get_transitions <issue_key>
#   List available transitions for an issue. Useful to discover transition IDs.
atlassian_get_transitions() {
  local issue_key="$1"
  atlassian_get "rest/api/2/issue/${issue_key}/transitions"
}
