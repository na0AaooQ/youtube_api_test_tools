#!/usr/bin/env bash
#############################################
# YouTubeコメントスレッド一覧を取得するためのテストスクリプト
#
# 使用する環境変数:
#   YOUTUBE_ACCESS_TOKEN
#   MODERATION_STATUS
#
# 実行例:
#   MODERATION_STATUS=published ./test_youtube_comment_threads_list.sh
#
# 保留中コメントを確認する場合:
#   MODERATION_STATUS=heldForReview ./test_youtube_comment_threads_list.sh
#
# 取得結果をファイルに保存する場合:
#   MODERATION_STATUS=published ./test_youtube_comment_threads_list.sh > youtube_comment_threads_list.txt
#
# 保存した結果を確認する例:
#   head -5 youtube_comment_threads_list.txt
#
# 特定のコメントIDを検索する例:
#   grep -A 2 -B 2 "COMMENT_ID" youtube_comment_threads_list.txt
#
#############################################
set -euo pipefail

: "${YOUTUBE_ACCESS_TOKEN:?YOUTUBE_ACCESS_TOKEN is required}"

TEST_VIDEO_ID="${TEST_VIDEO_ID:-KtQhTLYhwDc}"
MODERATION_STATUS="${MODERATION_STATUS:-published}"

case "$MODERATION_STATUS" in
  published|heldForReview)
    ;;
  *)
    printf 'MODERATION_STATUS must be published or heldForReview.\n' >&2
    exit 1
    ;;
esac

for required_command in curl jq; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$required_command" >&2
    exit 1
  fi
done

response_file="$(mktemp "${TMPDIR:-/tmp}/youtube-comment-threads.XXXXXX")"
trap 'rm -f "$response_file"' EXIT

if ! http_status="$(curl -sS -o "$response_file" -w '%{http_code}' -G \
  "https://www.googleapis.com/youtube/v3/commentThreads" \
  -H "Authorization: Bearer ${YOUTUBE_ACCESS_TOKEN}" \
  --data-urlencode "part=snippet" \
  --data-urlencode "videoId=${TEST_VIDEO_ID}" \
  --data-urlencode "moderationStatus=${MODERATION_STATUS}" \
  --data-urlencode "textFormat=plainText" \
  --data-urlencode "maxResults=100")"; then
  printf 'commentThreads.list request failed.\n' >&2
  exit 1
fi

if [ "$http_status" != "200" ]; then
  printf 'commentThreads.list failed (HTTP %s).\n' "$http_status" >&2
  if ! jq . "$response_file" >&2; then
    printf 'API error response was not JSON.\n' >&2
  fi
  exit 1
fi

jq --arg status "$MODERATION_STATUS" '{
  moderationStatus: $status,
  nextPageToken: (.nextPageToken // null),
  comments: [
    .items[] | {
      threadId: .id,
      topLevelCommentId: .snippet.topLevelComment.id,
      text: (.snippet.topLevelComment.snippet.textOriginal //
        .snippet.topLevelComment.snippet.textDisplay)
    }
  ]
}' "$response_file"
