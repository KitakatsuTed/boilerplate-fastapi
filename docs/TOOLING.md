# ツールとスキル

このドキュメントでは、FastAPIボイラープレートプロジェクトで使用するツールとClaude Codeスキルの使い方を説明します。

## 📚 関連ドキュメント

- [../README.md](../README.md) - プロジェクト概要
- [../CLAUDE.md](../CLAUDE.md) - コアガイドライン

**開発環境とコーディング**
- [SETUP.md](SETUP.md) - 開発環境セットアップ
- [CODING_STANDARDS.md](CODING_STANDARDS.md) - コーディング規約

**テストと品質**
- [TESTING.md](TESTING.md) - テストの書き方
- [SECURITY.md](SECURITY.md) - セキュリティ対策

**データベースとパフォーマンス**
- [MIGRATIONS.md](MIGRATIONS.md) - マイグレーション
- [PERFORMANCE.md](PERFORMANCE.md) - パフォーマンス最適化

**ツールとデプロイ**
- [FAQ.md](FAQ.md) - よくある質問

**アーキテクチャ**
- [ARCHITECTURE.md](ARCHITECTURE.md) - アーキテクチャ設計

---

## 概要

このプロジェクトでは、以下のツールとスキルを提供しています：

1. **Claude Codeスキル**: 新しいエンドポイント・モデルの追加、セキュリティ・パフォーマンスレビュー
2. **scaffold.sh**: モデル・エンドポイント・テストの一括生成
3. **シェルスクリプト**: 開発効率化スクリプト

## 1. Claude Codeスキル

Claude Codeには、このプロジェクトで使用できる専用スキルが用意されています。

### `/add-endpoint` - 新しいエンドポイント追加

ガイドラインに従って、モデル、スキーマ、リポジトリ、エンドポイント、テストを自動生成します。

#### 使い方

```bash
/add-endpoint
```

Claude Codeが対話形式で以下を質問します：
- リソース名（例: "post"、"product"、"comment"）
- フィールド一覧（例: "title:str", "content:text", "published:bool"）
- 認証が必要か（yes/no）
- ユーザーとの関連（yes/no）

#### 自動的に組み込む機能

- 型ヒント（すべての関数）
- 非同期処理（async/await）
- ページネーション（limit/offset、デフォルト20、最大100）
- 認証（必要に応じて `get_current_user` 依存性）
- バリデーション（Pydanticスキーマ）
- エラーハンドリング（404, 403など）
- N+1クエリ回避（`selectinload()`）

### `/add-model` - 新しいDBモデル追加

データベースモデルを追加します（エンドポイントなし）。

#### 使い方

```bash
/add-model
```

#### 自動的に設定する項目

- 主キー（id、Integer、自動インクリメント）
- インデックス（検索対象フィールド）
- 外部キー制約（リレーションシップ）
- NOT NULL制約（必須フィールド）
- UNIQUE制約（重複不可フィールド）
- タイムスタンプ（created_at, updated_at）

### `/security-check` - セキュリティレビュー

OWASP Top 10に基づいてセキュリティレビューを実行し、マークダウンレポートを生成します。

#### 使い方

```bash
/security-check
```

#### チェック項目

- SQLインジェクション
- XSS（クロスサイトスクリプティング）
- 認証・認可の欠如
- 機密情報漏洩（ハードコードされたシークレット）
- データバリデーションの欠如

詳細は[SECURITY.md](SECURITY.md)を参照してください。

### `/performance-check` - パフォーマンスレビュー

パフォーマンスの問題を検出し、最適化提案を含むマークダウンレポートを生成します。

#### 使い方

```bash
/performance-check
```

#### チェック項目

- N+1クエリ
- ページネーション欠如
- ブロッキングI/O
- 接続プール設定
- 非効率なクエリ

詳細は[PERFORMANCE.md](PERFORMANCE.md)を参照してください。

### `/vulnerability-scan` - 脆弱性スキャン

依存関係の脆弱性スキャンを実行します。

#### 使い方

```bash
/vulnerability-scan
```

#### 実行内容

- **bandit**: Pythonコード静的解析
- **safety**: 依存関係脆弱性スキャン
- **pip-audit**: 依存関係脆弱性スキャン

#### 出力

- `vulnerability-scan-report.md`: 脆弱性レポート（重大度・修正方法含む）

#### 推奨頻度

- ローカル開発: 毎週
- CI/CD: プルリクエスト時に自動実行

詳細は [/vulnerability-scan スキル](../.claude/skills/vulnerability-scan/SKILL.md) を参照してください。

## 2. scaffold.sh

scaffold.shは、モデル・エンドポイント・テストを一括生成するシェルスクリプトです。

### 使い方

```bash
./bin/scaffold.sh <model_name> <field1:type> <field2:type> ...
```

### 例

```bash
# Postモデルを生成
./bin/scaffold.sh post title:str content:text published:bool

# 生成されるファイル:
# - app/models/post.py
# - app/schemas/post/
# - app/db/repositories/post.py
# - app/api/v1/endpoints/posts.py
# - tests/test_api/test_posts.py
# - マイグレーション
```

### サポートされる型

- `str`: 文字列（VARCHAR）
- `text`: 長い文字列（TEXT）
- `int`: 整数
- `float`: 浮動小数点
- `bool`: 真偽値
- `datetime`: 日時

### オプション

- `:optional` - NULL許可
- `:unique` - ユニーク制約
- `:index` - インデックス作成

```bash
# 例: emailをユニーク・インデックス付きで作成
./bin/scaffold.sh user email:str:unique:index password:str
```

## 3. シェルスクリプト

プロジェクトには、開発を効率化するシェルスクリプトが用意されています。

### bin/dev.sh - 開発サーバー起動

```bash
./bin/dev.sh
```

ホットリロード付きで開発サーバーを起動します。

### bin/format.sh - コードフォーマット

```bash
./bin/format.sh
```

Ruffでコードをフォーマット・リントします。

### bin/test.sh - テスト実行

```bash
./bin/test.sh
```

カバレッジ付きでテストを実行します。

### bin/ci-local.sh - CI相当のチェック

```bash
./bin/ci-local.sh
```

Ruffチェック、テスト実行、カバレッジレポート生成を一括で実行します。

### bin/reset_db.sh - データベースリセット

```bash
./bin/reset_db.sh
```

データベースを削除、作成、マイグレーション適用、サンプルデータ投入を一括で実行します。

## 4. プルリクエストのガイドライン

### 1. ブランチを作成

```bash
# 最新のmainブランチを取得
git checkout main
git pull origin main

# フィーチャーブランチを作成
git checkout -b feature/your-feature-name
```

### 2. 変更を実装

- コーディング規約に従ってコードを書く（[CODING_STANDARDS.md](CODING_STANDARDS.md)参照）
- テストを追加する（[TESTING.md](TESTING.md)参照）
- ドキュメントを更新する（必要に応じて）

### 3. ローカルでチェック

```bash
# フォーマットとリント
./bin/format.sh
ruff check .

# テスト実行
./bin/test.sh

# CI相当のチェック
./bin/ci-local.sh
```

### 4. コミット

```bash
# ステージング
git add .

# コミット（pre-commitフックが自動実行される）
git commit -m "Add: 新機能の説明"
```

#### コミットメッセージの規約

- `Add: 新機能追加`
- `Fix: バグ修正`
- `Update: 既存機能の更新`
- `Refactor: リファクタリング`
- `Docs: ドキュメント更新`
- `Test: テスト追加・修正`
- `Chore: その他（依存関係更新など）`

### 5. プッシュ

```bash
git push origin feature/your-feature-name
```

### 6. プルリクエストを作成

GitHubで「Compare & pull request」ボタンをクリックし、以下を記入：

#### プルリクエストテンプレート

```markdown
## 概要
このプルリクエストの目的を簡潔に説明してください。

## 変更内容
- 変更点1
- 変更点2
- 変更点3

## 関連Issue
Closes #123

## テスト方法
1. ステップ1
2. ステップ2
3. 期待される結果

## チェックリスト
- [ ] コーディング規約に従っている
- [ ] テストを追加した
- [ ] テストがすべて通る
- [ ] ドキュメントを更新した（必要に応じて）
- [ ] `/security-check`、`/performance-check`、`/vulnerability-scan` を実行した
```

### 7. レビューとマージ

- メンテナーがレビューします
- 必要に応じて修正を行います
- 承認されたらマージされます

## レビュー前チェックリスト

コミット前に以下を確認してください：

- [ ] 型ヒントがすべての関数にある
- [ ] Pydanticスキーマでバリデーションしている
- [ ] 非同期関数を使用している（`async def`）
- [ ] BaseRepositoryパターンを使用している（CRUD操作の再利用）
- [ ] 1ファイル1クラスの原則に従っている
- [ ] Mixinを使用していない
- [ ] N+1クエリがない（`selectinload()`を使用）
- [ ] ページネーションを実装している（`skip`, `limit`）
- [ ] 認証が必要なエンドポイントに`get_current_user`を追加している
- [ ] テストを書いた
- [ ] Ruffチェックが通る（`ruff check .`）
- [ ] `/security-check`、`/performance-check`、`/vulnerability-scan` を実行した

## まとめ

- **Claude Codeスキル**: `/add-endpoint`、`/add-model`、`/security-check`、`/performance-check`、`/vulnerability-scan`
- **scaffold.sh**: モデル・エンドポイント・テストの一括生成
- **シェルスクリプト**: dev.sh、format.sh、test.sh、ci-local.sh、reset_db.sh
- **プルリクエスト**: レビュー前チェックリストを確認

## 次のステップ

ツールとスキルの使い方を理解したら：

- [ARCHITECTURE.md](ARCHITECTURE.md) - アーキテクチャ設計を理解
