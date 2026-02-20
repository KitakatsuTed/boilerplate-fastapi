# FastAPI Boilerplate - 本番対応のFastAPIテンプレート

本番環境で使える、柔軟で拡張性の高いFastAPIボイラープレートです。POCや新規開発案件で素早くWebサービスを立ち上げるために設計されています。

## ✨ 特徴

### 🔐 柔軟な認証システム
プロジェクトに応じて最適な認証方式を選択できます：
- **JWT認証**（推奨）: トークンベース、API向け、PyJWT使用
- **セッション認証**: Cookieベース、IDパスワード、itsdangerous使用
- **OAuth2外部認証**: Google、GitHub等の外部認証（将来実装）
- **認証なし**: 認証が不要なプロジェクト向け

### 💾 複数のデータベース対応
開発ステージや要件に応じてデータベースを選択できます：
- **PostgreSQL**: 本番推奨、SQLAlchemy + asyncpg（非同期）
- **MySQL**: SQLAlchemy + aiomysql（非同期）
- **SQLite**: 開発・プロトタイプ向け、SQLAlchemy + aiosqlite（非同期）

### 🏗️ クリーンアーキテクチャ
- **BaseRepositoryパターン**: 型安全な汎用CRUD操作（`BaseRepository[ModelType]`）
- **1ファイル1クラスの原則**: 保守性と可読性を向上
- **Mixinを使用しない**: コードの明示性と理解しやすさ
- **依存性注入**: FastAPIのDIシステムを活用

### 🚀 開発速度の向上
- **scaffold.sh**: Railsライクな一括生成スクリプト
  ```bash
  ./bin/scaffold.sh post title:str content:text published:bool
  ```
  モデル、スキーマ、リポジトリ、エンドポイント、テスト、マイグレーションを自動生成

- **便利なシェルスクリプト群**:
  - `dev.sh`: 開発サーバー起動
  - `migrate.sh`: マイグレーション実行
  - `seed.sh`: サンプルデータ投入
  - `reset_db.sh`: データベースリセット
  - `test.sh`: カバレッジ付きテスト実行
  - `format.sh`: コードフォーマット
  - その他多数

### 🔒 本番品質
- **セキュリティ**: OWASP Top 10準拠、パスワードハッシュ化、JWT署名検証
- **パフォーマンス**: N+1クエリ回避、ページネーション、接続プール最適化
- **エラーハンドリング**: 一貫した例外処理、適切なHTTPステータスコード
- **ロギング**: 構造化ロギング（JSON形式）、相関ID、CloudWatch対応

### 🤖 AI連携（オプショナル）
- AWS Bedrock統合（Claude、Titan等）
- マルチプロバイダー対応設計（OpenAI、Anthropic APIも将来対応可能）
- ストリーミングレスポンス対応

### 👥 チーム品質統一
- **CLAUDE.md**: プロジェクト固有のガイドライン、Claude Codeが自動読み込み
- **Claude Codeスキル群**:
  - `/boilerplate-fastapi`: プロジェクトセットアップ
  - `/add-endpoint`: 新エンドポイント追加
  - `/add-model`: 新DBモデル追加
  - `/security-check`: セキュリティレビュー
  - `/performance-check`: パフォーマンスレビュー
  - `/vulnerability-scan`: 脆弱性スキャン（bandit、safety、pip-audit）

## 🚀 クイックスタート

### 1. リポジトリのクローン

```bash
# GitHubテンプレートから新規リポジトリを作成
# 「Use this template」ボタンをクリック

# または直接クローン
git clone https://github.com/yourusername/boilerplate-fastapi.git my-new-project
cd my-new-project
```

### 2. プロジェクトの初期化

```bash
# setup.shスクリプトを実行（対話的に設定）
bash setup.sh
```

対話的に以下を選択します：
- プロジェクト名
- Pythonバージョン（3.11/3.12）
- 認証方式（JWT/Session/OAuth2/None）
- データベース（PostgreSQL/MySQL/SQLite）
- AI連携の有無

スクリプトが自動的に：
- `.env`ファイルを生成（SECRET_KEYも自動生成）
- 不要なファイルを削除
- 仮想環境を作成（`uv venv`）
- 依存関係をインストール
- pre-commitフックをインストール

### 3. 環境変数の設定

`.env`ファイルを編集して、必要な設定を調整：

```bash
# データベース設定（PostgreSQLの例）
POSTGRES_SERVER=localhost
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=fastapi_db

# JWT認証の場合（SECRET_KEYは自動生成済み）
AUTH_TYPE=jwt
ACCESS_TOKEN_EXPIRE_MINUTES=30

# AI連携（オプション）
AWS_REGION=us-east-1
AWS_BEDROCK_MODEL_ID=us.anthropic.claude-sonnet-4-5-20250929-v1:0
```

### 4. データベースの起動

```bash
# PostgreSQLの場合
docker-compose up -d postgres

# MySQLの場合
docker-compose up -d mysql

# SQLiteの場合（Dockerは不要）
# ファイルベースのため、そのまま次へ
```

### 5. マイグレーションの実行

```bash
# 仮想環境をアクティベート（setup.shで作成済み）
source .venv/bin/activate

# マイグレーション実行
alembic upgrade head
```

### 6. アプリケーションの起動

```bash
# 開発サーバー起動
uvicorn app.main:app --reload

# または便利スクリプトを使用
./bin/dev.sh
```

### 7. APIドキュメントの確認

ブラウザで以下を開く：
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
- ヘルスチェック: http://localhost:8000/health

## 📁 ディレクトリ構造

```
boilerplate-fastapi/
├── app/                          # FastAPIアプリケーション
│   ├── main.py                   # エントリーポイント
│   ├── dependencies.py           # 依存性注入プロバイダー
│   ├── api/v1/                   # バージョン管理されたAPI
│   │   ├── endpoints/            # エンドポイント（1ファイル1ルーター）
│   │   │   ├── auth.py           # 認証エンドポイント
│   │   │   └── users.py          # ユーザー管理
│   │   └── router.py             # ルート集約
│   ├── auth/
│   │   └── providers/            # 認証プロバイダー（1ファイル1クラス）
│   │       ├── base.py           # BaseAuthProvider抽象クラス
│   │       ├── jwt_provider.py   # JWT実装
│   │       └── login_password_provider.py  # セッション実装
│   ├── core/                     # コアコンポーネント
│   │   ├── config.py             # 設定管理（Pydantic Settings）
│   │   ├── logger.py             # ロギング設定
│   │   ├── middlewares.py        # ミドルウェア
│   │   ├── handlers.py           # 例外ハンドラー
│   │   └── exceptions/           # カスタム例外（1ファイル1クラス）
│   ├── db/                       # データベース層
│   │   ├── base.py               # SQLAlchemy Base
│   │   ├── session.py            # セッション管理
│   │   └── repositories/         # リポジトリ（1ファイル1クラス）
│   │       ├── base.py           # BaseRepository[ModelType]
│   │       └── user.py           # UserRepository
│   ├── models/                   # ORMモデル（1ファイル1クラス）
│   │   └── user.py               # Userモデル
│   ├── schemas/                  # Pydanticスキーマ（1ファイル1クラス）
│   │   ├── user/
│   │   │   ├── base.py           # UserBase
│   │   │   ├── create.py         # UserCreate
│   │   │   ├── update.py         # UserUpdate
│   │   │   └── response.py       # UserResponse
│   │   └── token/
│   └── utils/                    # ユーティリティ
│       └── security.py           # パスワードハッシュ
├── tests/                        # テスト
│   ├── conftest.py               # pytestフィクスチャ
│   └── test_api/
├── alembic/                      # データベースマイグレーション
│   ├── versions/
│   └── env.py
├── bin/                          # 開発用シェルスクリプト
│   ├── scaffold.sh               # モデル/スキーマ/エンドポイント一括生成
│   ├── dev.sh                    # 開発サーバー起動
│   ├── migrate.sh                # マイグレーション
│   ├── test.sh                   # テスト実行
│   └── ...
├── .claude/                      # Claude Codeスキル
│   └── skills/
│       ├── boilerplate-fastapi/
│       ├── add-endpoint/
│       ├── add-model/
│       ├── security-check/
│       └── performance-check/
├── .github/
│   └── workflows/                # CI/CD設定
├── setup.sh                      # プロジェクト初期化スクリプト
├── pyproject.toml                # 依存関係、Ruff設定
├── .env.example                  # 環境変数サンプル
├── docker-compose.yml            # 開発用Docker構成
├── Dockerfile                    # 本番用イメージ
├── .pre-commit-config.yaml       # pre-commitフック
├── CLAUDE.md                     # プロジェクトガイドライン
└── docs/                         # 詳細ドキュメント
    ├── SETUP.md                  # 開発環境セットアップ
    ├── CODING_STANDARDS.md       # コーディング規約
    ├── TESTING.md                # テストの書き方
    ├── SECURITY.md               # セキュリティ対策
    ├── MIGRATIONS.md             # マイグレーション
    ├── PERFORMANCE.md            # パフォーマンス最適化
    ├── FAQ.md                    # よくある質問
    ├── TOOLING.md                # スキルとツール
    └── ARCHITECTURE.md           # アーキテクチャ設計
```

## 🛠️ 開発ワークフロー

### 新しいエンドポイントの追加

**方法1: scaffold.sh（推奨）**

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

**方法2: Claude Codeスキル**

```bash
/add-endpoint
```

対話的にリソース名、フィールド、認証の有無を質問され、自動生成されます。

### テストの実行

```bash
# カバレッジ付きテスト実行
./bin/test.sh

# または直接
pytest tests/ -v --cov=app
```

### コードフォーマット

```bash
# Ruffでフォーマット
./bin/format.sh

# または直接
ruff check .
ruff format .
```

### マイグレーション

```bash
# 新しいマイグレーション作成
./bin/migrate.sh revision "Add new column"

# マイグレーション適用
./bin/migrate.sh upgrade

# ロールバック
./bin/migrate.sh downgrade -1
```

### セキュリティ・パフォーマンスチェック

```bash
# Claude Codeスキルでチェック
/security-check
/performance-check
/vulnerability-scan
```

OWASP Top 10準拠のセキュリティレビュー、N+1クエリ検出などのパフォーマンスレビュー、依存関係の脆弱性スキャンを実行します。

### フロントエンド連携

#### OpenAPI自動生成

FastAPIが自動的に`/docs`（Swagger UI）と`/openapi.json`を生成します。

フロントエンドで`openapi-typescript`を使って型定義を自動生成:

```bash
# フロントエンド側
npx openapi-typescript http://localhost:8000/openapi.json -o src/types/api.ts
```

#### CORS設定

`.env`ファイルで設定:

```bash
BACKEND_CORS_ORIGINS=["http://localhost:3000","http://localhost:8000"]
```

### CI/CDパイプライン

**GitHub Actions例**（`.github/workflows/test.yml`）:

```yaml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: 3.11
      - name: Install dependencies
        run: pip install -e ".[dev]"
      - name: Run tests
        run: pytest tests/ -v --cov=app
```

詳細は[docs/SETUP.md](docs/SETUP.md)を参照してください。

## 🔧 環境変数

| 変数名 | 説明 | デフォルト値 |
|--------|------|--------------|
| `PROJECT_NAME` | プロジェクト名 | `"My FastAPI App"` |
| `AUTH_TYPE` | 認証方式（jwt/login_password/oauth2/none） | `jwt` |
| `DB_TYPE` | データベースタイプ（postgresql/mysql/sqlite） | `postgresql` |
| `SECRET_KEY` | JWT署名キー（本番では必ず変更） | - |
| `ALGORITHM` | JWT署名アルゴリズム | `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | アクセストークン有効期限（分） | `30` |
| `POSTGRES_SERVER` | PostgreSQLホスト | `localhost` |
| `POSTGRES_USER` | PostgreSQLユーザー | `postgres` |
| `POSTGRES_PASSWORD` | PostgreSQLパスワード | `postgres` |
| `POSTGRES_DB` | PostgreSQLデータベース名 | `fastapi_db` |
| `AWS_REGION` | AWSリージョン（AI連携） | `us-east-1` |
| `AWS_BEDROCK_MODEL_ID` | Bedrockモデル | `us.anthropic.claude-sonnet-4-5-20250929-v1:0` |
| `BACKEND_CORS_ORIGINS` | CORS許可オリジン | `["http://localhost:3000"]` |
| `LOG_LEVEL` | ログレベル | `INFO` |
| `LOG_FORMAT` | ログ形式（json/text） | `json` |

詳細は[.env.example](.env.example)を参照してください。

## 🚢 デプロイ

### Dockerイメージのビルド

```bash
# イメージビルド
./bin/docker-build.sh

# または直接
docker build -t my-fastapi-app .
```

### Docker Composeでデプロイ

```bash
# 本番用docker-compose.yml（別途作成）
docker-compose -f docker-compose.prod.yml up -d
```

### クラウドへのデプロイ

1. コンテナレジストリにイメージをプッシュ
2. コンテナオーケストレーションサービスでデプロイ
3. ロードバランサーで負荷分散
4. シークレットマネージャーで環境変数を管理

## 👥 チームでの利用方法

このボイラープレートは、チーム全体で品質を統一するための仕組みが組み込まれています。

### CLAUDE.mdによるガイドライン統一

`CLAUDE.md`には、プロジェクトのコアガイドライン（アーキテクチャの原則、よく使う開発タスク）が簡潔にまとめられています。詳細なドキュメントはdocs/ディレクトリに分離されており、必要に応じて参照できます。Claude Codeが自動的に読み込んで従います。

### Claude Codeスキルの活用

チームメンバー全員が同じスキルを使用することで、一貫した品質のコードを生成できます：

- **`/boilerplate-fastapi`**: プロジェクトセットアップ
- **`/add-endpoint`**: ガイドラインに従ったエンドポイント自動生成
- **`/add-model`**: データベースモデルの標準パターン適用
- **`/security-check`**: OWASP Top 10準拠のセキュリティレビュー
- **`/performance-check`**: N+1クエリ、ページネーションなどの自動検出
- **`/vulnerability-scan`**: 依存関係の脆弱性スキャン（bandit、safety、pip-audit）

### ワークフロー

1. ボイラープレートをクローン
2. `setup.sh`で初期化（認証方式・データベースを選択）
3. `CLAUDE.md`と`.claude/skills/`がプロジェクトに含まれる
4. チームメンバー全員が同じガイドライン・スキルを使用
5. Claude Codeが一貫した品質でコードを生成
6. レビュー工数削減、品質向上

## 📚 ドキュメント

- [CLAUDE.md](CLAUDE.md) - プロジェクト固有のガイドライン（Claude Codeが自動読み込み）

### 開発環境とコーディング
- [docs/SETUP.md](docs/SETUP.md) - 開発環境セットアップ
- [docs/CODING_STANDARDS.md](docs/CODING_STANDARDS.md) - コーディング規約

### テストと品質
- [docs/TESTING.md](docs/TESTING.md) - テストの書き方
- [docs/SECURITY.md](docs/SECURITY.md) - セキュリティ対策

### データベースとパフォーマンス
- [docs/MIGRATIONS.md](docs/MIGRATIONS.md) - マイグレーション
- [docs/PERFORMANCE.md](docs/PERFORMANCE.md) - パフォーマンス最適化

### ツールとデプロイ
- [docs/TOOLING.md](docs/TOOLING.md) - Claude Codeスキルとscaffold.sh
- [docs/FAQ.md](docs/FAQ.md) - よくある質問

### アーキテクチャ
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - アーキテクチャ設計
