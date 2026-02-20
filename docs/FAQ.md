# よくある質問（FAQ）

このドキュメントでは、FastAPIボイラープレートプロジェクトに関するよくある質問と回答をまとめています。

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
- [TOOLING.md](TOOLING.md) - Claude Codeスキルとscaffold.sh

**アーキテクチャ**
- [ARCHITECTURE.md](ARCHITECTURE.md) - アーキテクチャ設計

---

## 環境構築関連

### Q1: uvが見つからない

**A**: パスを追加してください。

```bash
# パスを追加
export PATH="$HOME/.cargo/bin:$PATH"

# .bashrcや.zshrcに追加
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

詳細は[SETUP.md](SETUP.md)を参照してください。

### Q2: 依存関係を追加したい

**A**: `pyproject.toml`の`dependencies`または`optional-dependencies`に追加してください。

```toml
[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "new-package>=1.0.0",  # 追加
]
```

その後、再インストール：

```bash
uv pip install -e ".[dev]"
```

### Q3: データベース接続エラー

**A**: PostgreSQLが起動しているか確認してください。

```bash
# PostgreSQLが起動しているか確認
docker-compose ps

# 起動していない場合
docker-compose up -d postgres
```

詳細は[SETUP.md](SETUP.md)を参照してください。

## マイグレーション関連

### Q4: マイグレーションが失敗する

**A**: データベースをリセットしてください。

```bash
./bin/reset_db.sh
```

これにより、データベースを削除、作成、マイグレーション適用、サンプルデータ投入を一括で実行します。

⚠️ **警告**: このスクリプトは**開発環境専用**です。本番環境では絶対に実行しないでください。すべてのデータが削除されます。

詳細は[MIGRATIONS.md](MIGRATIONS.md)を参照してください。

### Q5: マイグレーションファイルが検出されない

**A**: モデルが正しくインポートされているか確認してください。

```python
# app/models/__init__.py に新しいモデルをインポート
from app.models.user import User
from app.models.post import Post  # 追加したモデル
```

詳細は[MIGRATIONS.md](MIGRATIONS.md)を参照してください。

## 開発ツール関連

### Q6: pre-commitフックをスキップしたい

**A**: `--no-verify`フラグを使用（推奨しません）。

```bash
git commit --no-verify -m "Message"
```

ただし、CIで失敗する可能性があるため、基本的にはフックを通過させてください。

詳細は[CODING_STANDARDS.md](CODING_STANDARDS.md)を参照してください。

### Q7: scaffold.shでモデルを生成したい

**A**: 以下のコマンドを実行してください。

```bash
./bin/scaffold.sh post title:str content:text published:bool
```

詳細は[TOOLING.md](TOOLING.md)を参照してください。

### Q8: CIでテストが失敗する

**A**: ローカルで`./bin/ci-local.sh`を実行して、CI相当のチェックを行ってください。

```bash
./bin/ci-local.sh
```

これにより、Ruffチェック、テスト実行、カバレッジレポート生成を一括で実行します。

詳細は[TESTING.md](TESTING.md)を参照してください。

## テスト関連

### Q9: テストが失敗する

**A**: まず、以下を確認してください：

```bash
# テストデータベースが存在するか確認
docker-compose ps

# データベースをリセット
./bin/reset_db.sh

# テスト実行
./bin/test.sh
```

詳細は[TESTING.md](TESTING.md)を参照してください。

### Q10: カバレッジが低い

**A**: 不足しているテストケースを追加してください。目標は80%以上です。

```bash
# HTMLレポート生成
pytest tests/ --cov=app --cov-report=html

# ブラウザでレポート確認
open htmlcov/index.html
```

詳細は[TESTING.md](TESTING.md)を参照してください。

## デプロイ関連

### Q11: 本番環境へのデプロイ方法

**A**: 基本的な流れ：

1. ステージング環境でテスト
2. データベースのバックアップ
3. マイグレーション適用
4. アプリケーションデプロイ
5. 動作確認

詳細はプロジェクトのデプロイ先に応じて、クラウドプロバイダーのドキュメントを参照してください。

### Q12: SECRET_KEYの生成方法

**A**: 以下のコマンドで生成できます。

```bash
openssl rand -hex 32
```

詳細は[SECURITY.md](SECURITY.md)を参照してください。

## パフォーマンス関連

### Q13: APIが遅い

**A**: 以下を確認してください：

1. N+1クエリがないか確認（`/performance-check`スキル実行）
2. ページネーションが実装されているか確認
3. 接続プール設定が適切か確認
4. インデックスが適切に設定されているか確認

詳細は[PERFORMANCE.md](PERFORMANCE.md)を参照してください。

### Q14: パフォーマンスレビューの実行方法

**A**: Claude Codeの`/performance-check`スキルを実行してください。

詳細は[TOOLING.md](TOOLING.md)を参照してください。

## セキュリティ関連

### Q15: セキュリティレビューの実行方法

**A**: Claude Codeの`/security-check`スキルを実行してください。

詳細は[TOOLING.md](TOOLING.md)を参照してください。

### Q16: 環境変数の管理方法

**A**: `.env`ファイルで管理します。

```bash
# .env.exampleをコピー
cp .env.example .env

# .envを編集
nano .env
```

**.gitignore**に`.env`を追加して、Gitにコミットしないようにしてください。

詳細は[SECURITY.md](SECURITY.md)を参照してください。

## その他

### Q17: ドキュメントの構成が分からない

**A**: 以下のドキュメントを参照してください：

- **開発環境**: [SETUP.md](SETUP.md)、[CODING_STANDARDS.md](CODING_STANDARDS.md)
- **テストと品質**: [TESTING.md](TESTING.md)、[SECURITY.md](SECURITY.md)
- **データベース**: [MIGRATIONS.md](MIGRATIONS.md)、[PERFORMANCE.md](PERFORMANCE.md)
- **ツール**: [TOOLING.md](TOOLING.md)
- **アーキテクチャ**: [ARCHITECTURE.md](ARCHITECTURE.md)

### Q18: バグを見つけた場合

**A**: GitHub Issuesで報告してください。

### Q19: 機能リクエスト

**A**: GitHub Discussionsで提案してください。

## まとめ

このFAQで解決しない問題がある場合は、各ドキュメントを参照するか、GitHub Issuesで質問してください。
