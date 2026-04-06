#!/usr/bin/env bash
# fetch-tickets.sh — Fetch tickets recently assigned to me and print their details

set -euo pipefail

# Load .env
source "$(dirname "$0")/.env"

echo "Fetching recently assigned tickets from JIRA..."
echo ""

# Step 1 — get ticket keys assigned to me in the last 24h
KEYS=$(curl --silent \
  --request GET \
  --url "https://${JIRA_HOST}/rest/agile/1.0/board/${JIRA_BOARD_ID}/issue?jql=assignee%3DcurrentUser()%20AND%20assignee%20changed%20to%20currentUser()%20AFTER%20%22-24h%22%20AND%20project%3D${JIRA_PROJECT}%20AND%20status%3D%22To%20Do%22&maxResults=10&fields=summary" \
  --user "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
  --header "Accept: application/json" \
  | python3 -c "import sys,json; [print(i['key']) for i in json.load(sys.stdin).get('issues',[])]")

if [ -z "$KEYS" ]; then
  echo "No tickets recently assigned to you."
  exit 0
fi

# Step 2 — loop through each key and print details
for KEY in $KEYS; do
  echo "════════════════════════════════════════"
  echo "Fetching $KEY..."

  curl --silent \
    --request GET \
    --url "https://${JIRA_HOST}/rest/api/3/issue/${KEY}" \
    --user "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
    --header "Accept: application/json" \
    | python3 -c "
import sys, json

d = json.load(sys.stdin)
f = d['fields']

def extract_text(node):
    if node.get('type') == 'text':
        return node.get('text', '')
    return ''.join(extract_text(c) for c in node.get('content', []))

desc = f.get('description')
if not desc:
    description = '(no description)'
elif isinstance(desc, str):
    description = desc
else:
    description = extract_text(desc)

print('Key:        ', d['key'])
print('Summary:    ', f['summary'])
print('Status:     ', f['status']['name'])
print('Priority:   ', f['priority']['name'])
print('Assignee:   ', f['assignee']['displayName'] if f.get('assignee') else 'Unassigned')
print('Labels:     ', ', '.join(f.get('labels', [])) or 'none')
print('Description:', description)
"
  echo ""
done

echo "════════════════════════════════════════"
echo "Done."
