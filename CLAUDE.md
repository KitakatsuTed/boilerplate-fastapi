# FastAPI Boilerplate - プロジェクトガイドライン

このファイルは、Claude Codeが自動的に読み込むプロジェクト固有のガイドラインです。チーム全体で品質を統一するため、以下の原則に従ってください。

## 📚 関連ドキュメント

開発を開始する前に、以下のドキュメントを参照してください：

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

---

## アーキテクチャの原則

このプロジェクトは以下の原則に従っています：

- **依存性注入（DI）**: FastAPIのDIシステムを活用（データベースセッション、認証プロバイダー）
- **リポジトリパターン**: BaseRepository[ModelType]で型安全なCRUD操作
- **設定管理**: Pydantic Settingsで環境変数を管理（.envファイル）
- **エラーハンドリング**: BusinessException基底クラスを継承したカスタム例外
- **1ファイル1クラス**: 各クラスを独立したファイルに配置
- **Mixinを使用しない**: コードの明示性を優先

**詳細は[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)と[docs/CODING_STANDARDS.md](docs/CODING_STANDARDS.md)を参照してください。**

## よく使う開発タスク

### Scaffold生成（推奨）
```bash
./bin/scaffold.sh post title:str content:text published:bool
```
モデル、スキーマ、リポジトリ、エンドポイント、テスト、マイグレーションを自動生成します。

### 主要なシェルスクリプト
- `./bin/dev.sh` - 開発サーバー起動
- `./bin/test.sh` - テスト実行
- `./bin/migrate.sh` - マイグレーション管理
- `./bin/format.sh` - コードフォーマット

**詳細は[docs/TOOLING.md](docs/TOOLING.md)を参照してください。**

## データベース・認証の切り替え

`.env`ファイルで環境変数を変更するだけで、コード変更なしに切り替えられます：

- **データベース**: `DB_TYPE=postgresql|mysql|sqlite`
- **認証**: `AUTH_TYPE=jwt|login_password|oauth2|none`

**詳細は[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)の「環境変数と切り替え」を参照してください。**

## セキュリティ

セキュリティ対策（SQLインジェクション、パスワードハッシュ化、JWT署名検証等）の詳細は[docs/SECURITY.md](docs/SECURITY.md)を参照してください。

## ロギング

構造化ロギング（JSON形式、相関ID）は標準出力に出力されます。

## テスト

テストの書き方（非同期テスト、フィクスチャ、カバレッジ）の詳細は[docs/TESTING.md](docs/TESTING.md)を参照してください。

## マイグレーション

データベースマイグレーション（Alembic）の詳細は[docs/MIGRATIONS.md](docs/MIGRATIONS.md)を参照してください。

## パフォーマンス最適化

パフォーマンス最適化（N+1クエリ回避、ページネーション、接続プール）の詳細は[docs/PERFORMANCE.md](docs/PERFORMANCE.md)を参照してください。

## Claude Code スキルの活用

このプロジェクトでは、以下のカスタムスキルを提供しています：

- `/add-endpoint` - 新しいエンドポイント追加（モデル、スキーマ、リポジトリ、エンドポイント、テストを自動生成）
- `/add-model` - 新しいDBモデル追加（エンドポイントなし）
- `/security-check` - セキュリティレビュー（OWASP Top 10準拠）
- `/performance-check` - パフォーマンスレビュー（N+1クエリ、ページネーション等）
- `/vulnerability-scan` - 脆弱性スキャン（bandit、safety、pip-audit）

**詳細は[docs/TOOLING.md](docs/TOOLING.md)を参照してください。**

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

このガイドラインに従うことで、チーム全体で一貫した品質のコードを保つことができます。Claude Codeスキルを活用し、レビュー前チェックリストを確認することで、セキュリティとパフォーマンスの問題を事前に防ぎましょう。

詳細なドキュメントは[docs/](docs/)ディレクトリを参照してください。
