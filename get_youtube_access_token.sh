#!/usr/bin/env bash
#############################################
# YouTube Data API v3 用のアクセストークンを取得するスクリプト
#
# 使用する環境変数:
#   GOOGLE_CLIENT_ID
#   GOOGLE_CLIENT_SECRET
#   YOUTUBE_REFRESH_TOKEN
#
# 実行例:
#   ./get_youtube_access_token.sh
#
# 備考:
#   通常は、以下のようなエイリアス経由で実行します。
#    refresh_youtube_token
#
#   これにより、取得したアクセストークンが YOUTUBE_ACCESS_TOKEN に設定されます。
#
#############################################
set -euo pipefail

: "${GOOGLE_CLIENT_ID:?GOOGLE_CLIENT_ID is required}"
: "${GOOGLE_CLIENT_SECRET:?GOOGLE_CLIENT_SECRET is required}"
: "${YOUTUBE_REFRESH_TOKEN:?YOUTUBE_REFRESH_TOKEN is required}"

for required_command in curl jq; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$required_command" >&2
    exit 1
  fi
done

if ! response="$(curl -sS -X POST "https://oauth2.googleapis.com/token" \
  --data-urlencode "client_id=${GOOGLE_CLIENT_ID}" \
  --data-urlencode "client_secret=${GOOGLE_CLIENT_SECRET}" \
  --data-urlencode "refresh_token=${YOUTUBE_REFRESH_TOKEN}" \
  --data-urlencode "grant_type=refresh_token")"; then
  printf 'Failed to request access_token.\n' >&2
  exit 1
fi

if ! access_token="$(printf '%s' "$response" | jq -er \
  '.access_token | select(type == "string" and length > 0)' 2>/dev/null)"; then
  printf 'Failed to get access_token.\n' >&2
  if ! printf '%s\n' "$response" | jq . >&2; then
    printf 'Token endpoint returned a non-JSON response.\n' >&2
  fi
  exit 1
fi

printf '%s\n' "$access_token"
