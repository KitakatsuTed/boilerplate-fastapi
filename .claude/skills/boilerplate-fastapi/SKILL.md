---
name: boilerplate-fastapi
description: >
  FastAPIボイラープレートをGitリポジトリからクローンしてセットアップするスキル。
  柔軟な認証方式（JWT/Session/OAuth2/None）、複数DB対応（PostgreSQL/MySQL/SQLite）、
  AI連携（Bedrock等）、ロギングを含む本番対応のボイラープレート。
  GitHub、GitLab、BitBucket等のプラットフォームに対応。
---

# FastAPI Boilerplate Setup

このスキルは、boilerplate-fastapiテンプレートリポジトリを使って、新しいFastAPIプロジェクトをセットアップします。

## 使い方

ユーザーが「FastAPIボイラープレートをセットアップしたい」「新しいFastAPIプロジェクトを作りたい」などと言った場合に実行します。

## 実行フロー

### 1. プロジェクト情報の収集

ユーザーに以下を質問します：

- **プロジェクト名**: デフォルト `my-fastapi-app`
- **Pythonバージョン**: 3.11（推奨） / 3.12
- **認証方式**:
  - JWT認証（推奨、トークンベース、API向け）
  - セッション認証（Cookie、IDパスワード）
  - OAuth2外部認証（将来実装）
  - 認証なし
- **データベース**:
  - PostgreSQL（本番推奨、SQLAlchemy + asyncpg）
  - MySQL（SQLAlchemy + aiomysql）
  - SQLite（開発・プロトタイプ、SQLAlchemy + aiosqlite）
- **AI連携**: Bedrock等を含めるか（y/N）

### 2. リポジトリのクローン

```bash
# GitHubテンプレートからクローン（または git clone）
git clone https://github.com/yourusername/boilerplate-fastapi.git {プロジェクト名}
cd {プロジェクト名}
```

### 3. setup.shスクリプトの実行

```bash
# 対話的にセットアップ
bash setup.sh
```

setup.shが自動的に以下を実行します：
- プロジェクト名を置換（pyproject.toml、READMEなど）
- Pythonバージョンを設定
- .envファイルを生成（SECRET_KEYも自動生成）
- 認証方式・データベースを設定
- 不要なファイルを削除（選択に応じて）
- uv仮想環境を作成（`uv venv --python {バージョン}`）
- 依存関係をインストール（選択に応じた extras）
- pre-commitフックをインストール

### 4. 次のステップを案内

ユーザーに以下を案内します：

```bash
# 1. .envファイルを編集（必要に応じて）
nano .env

# 2. データベースを起動（PostgreSQL/MySQLの場合）
docker-compose up -d postgres  # または mysql

# 3. マイグレーション実行
source .venv/bin/activate
alembic upgrade head

# 4. アプリケーション起動
uvicorn app.main:app --reload

# 5. APIドキュメント確認
# ブラウザで http://localhost:8000/docs を開く
```

## 含まれる機能

### 認証（選択可能）

- **JWT認証（PyJWT）**: トークンベース、アクセストークン（30分）+ リフレッシュトークン（7日）
- **セッション認証（Cookie）**: IDパスワード、itsdangerous使用
- **OAuth2外部認証**: Google、GitHub等（将来実装）
- **認証なし**: 認証が不要なプロジェクト向け

### データベース（選択可能）

- **PostgreSQL**: 本番推奨、SQLAlchemy + asyncpg（非同期）
- **MySQL**: SQLAlchemy + aiomysql（非同期）
- **SQLite**: 開発・プロトタイプ向け、SQLAlchemy + aiosqlite（非同期）

### 共通機能

- **BaseRepositoryパターン**: 型安全な汎用CRUD操作（`BaseRepository[ModelType]`）
- **1ファイル1クラスの原則**: 保守性と可読性を向上
- **AI連携（オプショナル）**: Bedrock、OpenAI、Anthropic等に対応
- **構造化ロギング**: 相関ID、JSON形式、CloudWatch対応
- **Ruff + pre-commit**: コードフォーマット・リント自動化
- **pytest**: 非同期テスト環境
- **Docker構成**: PostgreSQL/MySQL用のdocker-compose.yml
- **CI/CD設定**: GitHub Actions（test.yml、lint.yml）

## scaffold.shでの開発

新しいエンドポイントを追加する際は、scaffold.shを使用します：

```bash
# Postモデルとエンドポイントを一括生成
./bin/scaffold.sh post title:str content:text published:bool

# 生成されるファイル:
# - app/models/post.py
# - app/schemas/post/
# - app/db/repositories/post.py
# - app/api/v1/endpoints/posts.py
# - tests/test_api/test_posts.py
# - マイグレーション
```

## Claude Codeスキル

プロジェクトには、チーム品質統一のための以下のスキルが含まれます：

- `/add-endpoint`: 新エンドポイント追加
- `/add-model`: 新DBモデル追加
- `/security-check`: セキュリティレビュー（OWASP Top 10準拠）
- `/performance-check`: パフォーマンスレビュー（N+1クエリ検出など）

## ドキュメント

- **CLAUDE.md**: プロジェクト固有のガイドライン（Claude Codeが自動読み込み）
- **docs/SETUP.md**: 開発環境セットアップ
- **docs/CODING_STANDARDS.md**: コーディング規約
- **docs/TESTING.md**: テストの書き方
- **docs/SECURITY.md**: セキュリティ対策
- **docs/MIGRATIONS.md**: マイグレーション
- **docs/PERFORMANCE.md**: パフォーマンス最適化
- **docs/TOOLING.md**: Claude Codeスキルとscaffold.sh
- **docs/FAQ.md**: よくある質問
- **docs/ARCHITECTURE.md**: アーキテクチャ設計

## トラブルシューティング

### uv not found

```bash
# uvをインストール
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.cargo/bin:$PATH"
```

### データベース接続エラー

```bash
# PostgreSQLが起動しているか確認
docker-compose ps

# 起動していない場合
docker-compose up -d postgres
```

### マイグレーションエラー

```bash
# データベースをリセット
./bin/reset_db.sh
```

## セットアップ完了後

セットアップが完了したら、以下を確認してください：

- [ ] `.env`ファイルが正しく設定されている
- [ ] データベースが起動している
- [ ] マイグレーションが適用されている
- [ ] `http://localhost:8000/docs` でSwagger UIが表示される
- [ ] `/health` エンドポイントが正常に応答する

ユーザーに「セットアップが完了しました！」と伝え、次のステップ（新しいエンドポイント追加など）を提案してください。
