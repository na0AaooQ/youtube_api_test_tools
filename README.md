# youtube_api_test_tools
[YouTube Data API v3](https://developers.google.com/youtube/v3/docs/comments?hl=ja) のコメント取得API等の実行テスト用シェルスクリプト

`youtube_api_test_tools` は、[こめんとみまもり｜YouTube安心コメントフィルター](https://portfolio.na0aaooq.com/assets/pdf/youtube-comment-mimamori-introduction.pdf) の開発・検証用に作成した、YouTube Data API v3 の動作確認スクリプト集です。

https://github.com/na0AaooQ/youtube_api_test_tools

YouTubeコメントの取得、コメントスレッド一覧取得、コメントのモデレーション状態変更などを、ローカル環境から手動で確認するために使用します。

## 目的

このリポジトリは、主に以下の検証を行うためのものです。

- YouTube Data API v3 の OAuth 2.0 認証確認
- アクセストークン取得確認
- コメント単体の取得確認
- コメントスレッド一覧の取得確認
- コメントのモデレーション状態変更確認
  - `heldForReview`
  - `published`
- 「こめんとみまもり」開発時の YouTube API 挙動確認

## 注意事項

このリポジトリには、以下のような機密情報を含めないでください。

- Google OAuth Client ID
- Google OAuth Client Secret
- YouTube Refresh Token
- YouTube Access Token
- その他、Google アカウントや YouTube チャンネルに紐づく認証情報

認証情報は、ローカル環境の `~/.zshrc` など、Git 管理対象外の場所で管理します。

また、API実行結果にはコメント本文が含まれる場合があります。  
検証結果ファイルを保存する場合は、公開リポジトリへ誤ってコミットしないよう注意してください。

## 前提条件

ローカル環境に以下がインストールされていることを前提とします。

- `bash`
- `curl`
- `jq`

確認例:

```bash
bash --version
curl --version
jq --version
```

## 環境変数

各スクリプトの実行には、以下の環境変数を使用します。

```bash
GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET
YOUTUBE_REFRESH_TOKEN
YOUTUBE_ACCESS_TOKEN
```

例として、ローカルの `~/.zshrc` などに以下のような設定を行います。

```bash
export GOOGLE_CLIENT_ID="your-google-client-id"
export GOOGLE_CLIENT_SECRET="your-google-client-secret"
export YOUTUBE_REFRESH_TOKEN="your-youtube-refresh-token"

alias refresh_youtube_token='export YOUTUBE_ACCESS_TOKEN="$(/path/to/youtube_api_test_tools/get_youtube_access_token.sh)"'
```

設定後、以下を実行して環境変数を読み込みます。

```bash
source ~/.zshrc
```

## スクリプト一覧

### get_youtube_access_token.sh

YouTube Data API v3 用のアクセストークンを取得するスクリプトです。

使用する環境変数:

```bash
GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET
YOUTUBE_REFRESH_TOKEN
```

実行例:

```bash
./get_youtube_access_token.sh
```

通常は、以下のようなエイリアス経由で実行します。

```bash
refresh_youtube_token
```

これにより、取得したアクセストークンが `YOUTUBE_ACCESS_TOKEN` に設定されます。

### test_youtube_comment_get.sh

指定したコメントIDのコメント情報を取得するための検証スクリプトです。

使用する主な環境変数:

```bash
YOUTUBE_ACCESS_TOKEN
TEST_COMMENT_ID
```

実行例:

```bash
TEST_COMMENT_ID="COMMENT_ID" ./test_youtube_comment_get.sh
```

### test_youtube_comment_threads_list.sh

YouTubeコメントスレッド一覧を取得するための検証スクリプトです。

コメントのモデレーション状態ごとに取得確認できます。

使用する主な環境変数:

```bash
YOUTUBE_ACCESS_TOKEN
MODERATION_STATUS
```

実行例:

```bash
MODERATION_STATUS=published ./test_youtube_comment_threads_list.sh
```

保留中コメントを確認する場合:

```bash
MODERATION_STATUS=heldForReview ./test_youtube_comment_threads_list.sh
```

取得結果をファイルに保存する場合:

```bash
MODERATION_STATUS=published ./test_youtube_comment_threads_list.sh > youtube_comment_threads_list.txt
```

保存した結果を確認する例:

```bash
head -5 youtube_comment_threads_list.txt
```

特定のコメントIDを検索する例:

```bash
grep -A 2 -B 2 "COMMENT_ID" youtube_comment_threads_list.txt
```

### test_youtube_set_moderation_held.sh

指定したコメントのモデレーション状態を `heldForReview` に変更する検証スクリプトです。

使用する主な環境変数:

```bash
YOUTUBE_ACCESS_TOKEN
TEST_COMMENT_ID
```

実行例:

```bash
TEST_COMMENT_ID="COMMENT_ID" ./test_youtube_set_moderation_held.sh
```

実行時には確認プロンプトが表示されます。

```text
Set comment COMMENT_ID to heldForReview? Type YES to continue:
```

`YES` と入力した場合のみ、APIリクエストが実行されます。

注意:

YouTube Data API の仕様上、公開済みまたは拒否済みコメントを `heldForReview` に戻せない場合があります。  
このスクリプトは検証用のため、実行対象のコメントIDを必ず確認してから使用してください。

### test_youtube_set_moderation_published.sh

指定したコメントのモデレーション状態を `published` に変更する検証スクリプトです。

使用する主な環境変数:

```bash
YOUTUBE_ACCESS_TOKEN
TEST_COMMENT_ID
```

実行例:

```bash
TEST_COMMENT_ID="COMMENT_ID" ./test_youtube_set_moderation_published.sh
```

実行時には確認プロンプトが表示されます。

```text
Publish comment COMMENT_ID? Type YES to continue:
```

`YES` と入力した場合のみ、APIリクエストが実行されます。

## 基本的な実行手順

### 1. ディレクトリへ移動

```bash
cd /Users/aokinaohisa/GitHub/youtube_api_test_tools
```

### 2. 環境変数を読み込む

```bash
source ~/.zshrc
```

### 3. YouTube API用アクセストークンを取得する

```bash
refresh_youtube_token
```

### 4. コメントを `heldForReview` に変更する

```bash
TEST_COMMENT_ID="COMMENT_ID" ./test_youtube_set_moderation_held.sh
```

確認プロンプトで `YES` を入力します。

```text
Set comment COMMENT_ID to heldForReview? Type YES to continue: YES
```

成功すると、以下のようなメッセージが表示されます。

```text
Success: comment COMMENT_ID set to heldForReview (HTTP 204).
```

### 5. `heldForReview` のコメント一覧を確認する

```bash
MODERATION_STATUS=heldForReview ./test_youtube_comment_threads_list.sh
```

出力例:

```json
{
  "moderationStatus": "heldForReview",
  "nextPageToken": null,
  "comments": []
}
```

### 6. コメントを `published` に戻す

```bash
TEST_COMMENT_ID="COMMENT_ID" ./test_youtube_set_moderation_published.sh
```

確認プロンプトで `YES` を入力します。

```text
Publish comment COMMENT_ID? Type YES to continue: YES
```

成功すると、以下のようなメッセージが表示されます。

```text
Success: comment COMMENT_ID set to published (HTTP 204).
```

### 7. `published` のコメント一覧を保存する

```bash
MODERATION_STATUS=published ./test_youtube_comment_threads_list.sh > youtube_comment_threads_list.txt
```

### 8. 保存した結果を確認する

```bash
head -5 youtube_comment_threads_list.txt
```

コメントIDで検索する場合:

```bash
grep -A 2 -B 2 "COMMENT_ID" youtube_comment_threads_list.txt
```

## `.gitignore` 推奨設定

認証情報やAPIレスポンス結果を誤ってコミットしないよう、以下のような `.gitignore` を設定します。

```gitignore
# Local environment files
.env
.env.*
*.local

# API response outputs
youtube_comment_threads_list.txt
*_response.json
*_result.json
*.log

# macOS
.DS_Store
```

## セキュリティ上の注意

- `~/.zshrc` などに保存した認証情報は Git 管理しないでください。
- `YOUTUBE_REFRESH_TOKEN` は特に重要な機密情報です。
- APIレスポンスにはコメント本文が含まれる場合があります。
- コメント本文を含む検証結果ファイルは、原則として公開リポジトリへコミットしないでください。
- 誤って認証情報をコミットした場合は、該当ファイルを削除するだけでなく、Google Cloud 側で認証情報の無効化・再発行を検討してください。

## 関連ドキュメント

- YouTube Data API v3
  - CommentThreads: list
  - Comments: list
  - Comments: setModerationStatus
- Google OAuth 2.0
  - YouTube Data API v3 の認証・認可

## このツールの位置づけ

このリポジトリは、本番運用向けのアプリケーションではなく、「こめんとみまもり｜YouTube安心コメントフィルター」の開発・検証を補助するためのローカルAPIテストツールです。

本番機能へ組み込む前に、YouTube Data API v3 の挙動や制約を確認するために使用します。

なお、「こめんとみまもり｜YouTube安心コメントフィルター」のリポジトリは、以下のプライベートリポジトリになります。  
https://github.com/na0AaooQ/safe-comment-filter-app

## License

MIT License

Copyright (c) 2026 Aoki Naohisa

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
