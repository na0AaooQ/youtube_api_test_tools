#!/usr/bin/env bash
#############################################
# 指定したYouTubeコメントのモデレーション状態を heldForReview に変更するテストスクリプト
#
# 使用する環境変数:
#   YOUTUBE_ACCESS_TOKEN
#   TEST_COMMENT_ID
#
# 実行例:
#   TEST_COMMENT_ID="COMMENT_ID" ./test_youtube_set_moderation_held.sh
#
#   実行時には確認プロンプトが表示されます。
#     Set comment COMMENT_ID to heldForReview? Type YES to continue:
#       YES と入力した場合のみ、APIリクエストが実行されます。
#
# 注意:
#   YouTube Data API v3の仕様上、公開済みまたは拒否済みYouTubeコメントを heldForReview に戻せない場合があります。
#   このスクリプトはテスト用のため、実行対象のYouTubeコメントIDを必ず確認してから使用してください。
#
#############################################
set -euo pipefail

: "${YOUTUBE_ACCESS_TOKEN:?YOUTUBE_ACCESS_TOKEN is required}"

# テスト用YouTubeコメントIDは秘匿情報ではないので、そのままデフォルト値として記載している
TEST_COMMENT_ID="${TEST_COMMENT_ID:-Ugw2ITz0Gr0lOyRUrLJ4AaABAg}"

for required_command in curl jq; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$required_command" >&2
    exit 1
  fi
done

printf '%s\n' \
  'Google documents that a published or rejected comment cannot be changed back to heldForReview.' >&2
printf 'Set comment %s to heldForReview? Type YES to continue: ' \
  "$TEST_COMMENT_ID" >&2
read -r confirmation
if [ "$confirmation" != "YES" ]; then
  printf 'Cancelled.\n' >&2
  exit 1
fi

response_file="$(mktemp "${TMPDIR:-/tmp}/youtube-moderation-held.XXXXXX")"
trap 'rm -f "$response_file"' EXIT

if ! http_status="$(curl -sS -o "$response_file" -w '%{http_code}' -G -X POST \
  "https://www.googleapis.com/youtube/v3/comments/setModerationStatus" \
  -H "Authorization: Bearer ${YOUTUBE_ACCESS_TOKEN}" \
  --data-urlencode "id=${TEST_COMMENT_ID}" \
  --data-urlencode "moderationStatus=heldForReview")"; then
  printf 'comments.setModerationStatus request failed.\n' >&2
  exit 1
fi

if [ "$http_status" != "204" ]; then
  printf 'comments.setModerationStatus heldForReview failed (HTTP %s).\n' \
    "$http_status" >&2
  if [ -s "$response_file" ] && ! jq . "$response_file" >&2; then
    printf 'API error response was not JSON.\n' >&2
  fi
  exit 1
fi

printf 'Success: comment %s set to heldForReview (HTTP 204).\n' \
  "$TEST_COMMENT_ID"
