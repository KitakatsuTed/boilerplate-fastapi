# 開発環境セットアップ

このドキュメントでは、FastAPIボイラープレートの開発環境をセットアップする手順を説明します。

## 📚 関連ドキュメント

- [../README.md](../README.md) - プロジェクト概要
- [../CLAUDE.md](../CLAUDE.md) - コアガイドライン

**開発環境とコーディング**
- [CODING_STANDARDS.md](CODING_STANDARDS.md) - コーディング規約

**テストと品質**
- [TESTING.md](TESTING.md) - テストの書き方
- [SECURITY.md](SECURITY.md) - セキュリティ対策

**データベースとパフォーマンス**
- [MIGRATIONS.md](MIGRATIONS.md) - マイグレーション
- [PERFORMANCE.md](PERFORMANCE.md) - パフォーマンス最適化

**ツールとデプロイ**
- [TOOLING.md](TOOLING.md) - Claude Codeスキルとscaffold.sh
- [FAQ.md](FAQ.md) - よくある質問

**アーキテクチャ**
- [ARCHITECTURE.md](ARCHITECTURE.md) - アーキテクチャ設計

---

## 前提条件

- Python 3.11以上
- Docker（PostgreSQL/MySQLを使用する場合）
- Git

## セットアップ手順

### 1. リポジトリをクローン

```bash
git clone https://github.com/YOUR_USERNAME/boilerplate-fastapi.git
cd boilerplate-fastapi
```

### 2. uvのインストール

[uv](https://github.com/astral-sh/uv)は、高速なPythonパッケージインストーラーです。

```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windowsの場合はGitHubリリースからダウンロード
```

### 3. 仮想環境の作成と依存関係のインストール

```bash
# 仮想環境作成（Python 3.11推奨）
uv venv --python 3.11
source .venv/bin/activate  # Windowsの場合: .venv\Scripts\activate

# 開発用依存関係をすべてインストール
uv pip install -e ".[dev,jwt,session,postgresql,mysql,sqlite,ai]"
```

**extrasの説明**:
- `dev`: 開発ツール（Ruff、pytest、pre-commit等）
- `jwt`: JWT認証
- `session`: セッション認証
- `postgresql`: PostgreSQL用ドライバ（asyncpg）
- `mysql`: MySQL用ドライバ（aiomysql）
- `sqlite`: SQLite用ドライバ（aiosqlite）
- `ai`: AI連携（Bedrock等）

### 4. pre-commitフックのインストール

```bash
pre-commit install
```

これにより、コミット前に自動的にRuffでフォーマットとリントが実行されます。

### 5. データベースの起動

#### PostgreSQLを使用する場合

```bash
docker-compose up -d postgres
```

#### MySQLを使用する場合

```bash
docker-compose up -d mysql
```

#### SQLiteを使用する場合

Docker不要。そのまま次のステップへ。

### 6. 環境変数の設定

```bash
# .env.exampleをコピー
cp .env.example .env

# .envを編集（SECRET_KEYは setup.sh で自動生成されるため、手動で生成する場合）
# SECRET_KEY=$(openssl rand -hex 32)
```

**.envファイルの主要な設定**:
- `DATABASE_URL`: データベース接続URL
- `SECRET_KEY`: JWT署名用秘密鍵
- `AUTH_TYPE`: 認証方式（`jwt` / `login_password` / `none`）
- `ENVIRONMENT`: 実行環境（`development` / `staging` / `production`）

#### 環境変数の詳細説明

**DATABASE_URL**
- PostgreSQL: `postgresql+asyncpg://user:password@localhost:5432/dbname`
- MySQL: `mysql+aiomysql://user:password@localhost:3306/dbname`
- SQLite: `sqlite+aiosqlite:///./data.db`

**SECRET_KEY**
- JWT署名、セッショントークン暗号化に使用
- 32文字以上の16進数文字列を推奨
- `setup.sh`を使用した場合は自動生成されます
- 手動生成の場合: `openssl rand -hex 32`

**AUTH_TYPE**
- `jwt`: JWT認証（API向け、ステートレス）
- `login_password`: セッション認証（Cookie、ステートフル）
- `oauth2`: OAuth 2.0認証（将来実装予定）
- `none`: 認証なし

**ENVIRONMENT**
- `development`: 開発環境（デバッグモード有効）
- `staging`: ステージング環境
- `production`: 本番環境（デバッグモード無効）

**CORS_ORIGINS**
- 許可するオリジンのリスト（JSON配列形式）
- 例: `["http://localhost:3000","http://localhost:8000"]`

### 7. マイグレーションの実行

```bash
alembic upgrade head
```

これで、データベースにテーブルが作成されます。

### 8. アプリケーションの起動

```bash
# 開発サーバー起動
uvicorn app.main:app --reload

# または便利スクリプトを使用
./bin/dev.sh
```

ブラウザで [http://localhost:8000/docs](http://localhost:8000/docs) を開いて、Swagger UIが表示されることを確認します。

## セットアップ後の確認

セットアップが完了したら、以下のコマンドで動作確認を行ってください：

### ヘルスチェック

```bash
curl http://localhost:8000/health
```

期待されるレスポンス：
```json
{"status":"healthy"}
```

### APIドキュメント確認

```bash
# ブラウザで開く
open http://localhost:8000/docs
```

または、コマンドラインで確認：
```bash
curl http://localhost:8000/docs
```

Swagger UIが表示されれば成功です。

### チェックリスト

- [ ] `/health`エンドポイントが正常に応答する
- [ ] Swagger UI（`/docs`）が表示される
- [ ] データベースにテーブルが作成されている
- [ ] `pre-commit`がコミット前に実行される

## トラブルシューティング

### uvが見つからない

```bash
# パスを追加
export PATH="$HOME/.cargo/bin:$PATH"

# .bashrcや.zshrcに追加
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
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

## 次のステップ

開発環境のセットアップが完了したら：

- [CODING_STANDARDS.md](CODING_STANDARDS.md) - コーディング規約を確認
- [TOOLING.md](TOOLING.md) - Claude Codeスキルやscaffold.shの使い方を確認
- [TESTING.md](TESTING.md) - テストの書き方を確認
