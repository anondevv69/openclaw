#!/bin/bash

# PRISM Moltbook Poster
# Usage: ./post.sh "Your post content here"

set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SKILL_DIR"

# Load credentials
if [[ -f .env ]]; then
  export $(cat .env | xargs)
fi

if [[ -z "$MOLTBOOK_API_KEY" ]]; then
  echo "❌ MOLTBOOK_API_KEY not found in .env"
  exit 1
fi

if [[ -z "$1" ]]; then
  echo "Usage: $0 \"Your post content\""
  exit 1
fi

POST_CONTENT="$1"
SUBMOLT="${2:-general}"

echo "📡 Posting to Moltbook (submolt: $SUBMOLT)..."

# Post to Moltbook
RESPONSE=$(curl -s -X POST https://www.moltbook.com/api/v1/posts \
  -H "Authorization: Bearer $MOLTBOOK_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg submolt "$SUBMOLT" \
    --arg title "PRISM Alpha" \
    --arg content "$POST_CONTENT" \
    '{submolt: $submolt, title: $title, content: $content}')")

# Check response
if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  POST_ID=$(echo "$RESPONSE" | jq -r '.data.id // .data.post_id // empty')
  if [[ -n "$POST_ID" ]]; then
    echo "✅ Posted to Moltbook!"
    echo "Post ID: $POST_ID"
    echo "URL: https://moltbook.com/post/$POST_ID"
  else
    echo "✅ Posted to Moltbook!"
    echo "Response: $RESPONSE"
  fi
else
  echo "❌ Post failed"
  echo "Response: $RESPONSE"
  exit 1
fi
