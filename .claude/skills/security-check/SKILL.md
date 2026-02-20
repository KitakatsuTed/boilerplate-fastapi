---
name: security-check
description: >
  OWASP Top 10に基づくセキュリティレビュースキル。
  SQLインジェクション、XSS、認証・認可の問題、機密情報漏洩を自動検出。
  修正提案を含むマークダウンレポートを生成。
---

# Security Check Skill

OWASP Top 10に基づいてセキュリティレビューを実行します。

## 使い方

ユーザーが「セキュリティレビューして」「セキュリティチェックを実行して」「脆弱性を探して」などと言った場合に実行します。

## チェック項目

### 1. SQLインジェクション

**検出パターン**:
- 生SQL文字列の使用（`f"SELECT * FROM users WHERE id = {user_id}"`）
- `text()`、`execute()`の使用
- パラメータ化クエリの欠如

**✅ 安全な例**:
```python
# SQLAlchemyのORM使用
result = await db.execute(select(User).where(User.id == user_id))
```

**❌ 危険な例**:
```python
# 生SQL文字列（SQLインジェクションの危険）
query = f"SELECT * FROM users WHERE id = {user_id}"
result = await db.execute(text(query))
```

### 2. XSS（クロスサイトスクリプティング）

**検出パターン**:
- Pydanticスキーマの欠如
- HTMLレスポンスの直接返却（エスケープなし）
- `<script>`タグを含む文字列の返却

**✅ 安全な例**:
```python
# Pydanticスキーマでバリデーション
@router.post("/users/", response_model=UserResponse)
async def create_user(user_in: UserCreate, ...):
    # Pydanticが自動的にバリデーション
    ...
```

**❌ 危険な例**:
```python
# Pydanticスキーマなし
@router.post("/users/")
async def create_user(email: str, password: str):  # 型チェックのみ
    # バリデーションがない
    ...
```

### 3. 認証・認可の問題

**検出パターン**:
- 保護が必要なエンドポイントに`get_current_user`依存性がない
- パスワードハッシュ化の欠如（`hash_password()`が使われていない）
- JWT検証の欠如（`verify_token()`が使われていない）
- 所有者チェックの欠如（更新・削除時）

**✅ 安全な例**:
```python
# 認証必須
@router.delete("/posts/{post_id}")
async def delete_post(
    post_id: int,
    current_user: User = Depends(get_current_user),  # 認証
    db: AsyncSession = Depends(get_db),
):
    post = await repo.get_by_id(post_id)

    # 所有者チェック
    if post.user_id != current_user.id:
        raise ForbiddenError("You are not the owner")

    await repo.delete_by_id(post_id)
```

**❌ 危険な例**:
```python
# 認証なし
@router.delete("/posts/{post_id}")
async def delete_post(post_id: int, db: AsyncSession = Depends(get_db)):
    # 誰でも削除できてしまう
    await repo.delete_by_id(post_id)
```

### 4. 機密情報漏洩

**検出パターン**:
- ハードコードされたシークレット（`SECRET_KEY="hardcoded"`）
- ハードコードされたAPIキー（`API_KEY="sk-xxx"`）
- ハードコードされたパスワード（`password="admin123"`）
- `.env`ファイルの`.gitignore`欠如
- ログ出力にパスワードやトークンが含まれていないか

**✅ 安全な例**:
```python
# 環境変数で管理
from app.core.config import settings

SECRET_KEY = settings.SECRET_KEY  # .envから読み込み
```

**❌ 危険な例**:
```python
# ハードコード（危険）
SECRET_KEY = "my-super-secret-key-12345"
```

### 5. データバリデーション

**検出パターン**:
- リクエストボディにPydanticスキーマが使われているか
- クエリパラメータに型ヒントがあるか
- メールアドレスに`EmailStr`が使われているか
- パスワードに最低文字数制約があるか

**✅ 安全な例**:
```python
from pydantic import BaseModel, EmailStr, Field

class UserCreate(BaseModel):
    email: EmailStr  # メールアドレス形式検証
    password: str = Field(..., min_length=8)  # 最低8文字
```

**❌ 危険な例**:
```python
class UserCreate(BaseModel):
    email: str  # 形式検証なし
    password: str  # 文字数制約なし
```

## 実行フロー

### 1. プロジェクトルートで実行

```bash
/security-check
```

### 2. 全てのPythonファイルをスキャン

以下のディレクトリを対象に：
- `app/api/v1/endpoints/`
- `app/auth/providers/`
- `app/db/repositories/`
- `app/models/`
- `app/schemas/`
- `app/core/`
- `app/utils/`

### 3. レポート生成

マークダウンレポート（`security-report.md`）を生成：

```markdown
# セキュリティレビューレポート

生成日時: 2024-01-20 10:30:00

## 🔴 高リスク（即修正）

### SQLインジェクション - app/db/repositories/user.py:42

**問題**: 生SQL文字列の使用

**現在のコード**:
\`\`\`python
query = f"SELECT * FROM users WHERE id = {user_id}"
result = await db.execute(text(query))
\`\`\`

**修正案**:
\`\`\`python
# SQLAlchemyのORM使用
result = await db.execute(select(User).where(User.id == user_id))
\`\`\`

---

### ハードコードされたシークレット - app/core/config.py:15

**問題**: SECRET_KEYがハードコードされている

**現在のコード**:
\`\`\`python
SECRET_KEY = "my-super-secret-key-12345"
\`\`\`

**修正案**:
\`\`\`python
# 環境変数で管理
SECRET_KEY: str = Field(..., env="SECRET_KEY")
\`\`\`

## 🟡 中リスク（要確認）

### 認証欠如 - app/api/v1/endpoints/posts.py:25

**問題**: 保護が必要なエンドポイントに認証がない

**現在のコード**:
\`\`\`python
@router.delete("/posts/{id}")
async def delete_post(id: int, db: AsyncSession = Depends(get_db)):
    # 誰でも削除できてしまう
    await repo.delete_by_id(id)
\`\`\`

**修正案**:
\`\`\`python
@router.delete("/posts/{id}")
async def delete_post(
    id: int,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user)  # 追加
):
    post = await repo.get_by_id(id)
    if post.user_id != current_user.id:  # 所有者チェック
        raise ForbiddenError("You are not the owner")
    await repo.delete_by_id(id)
\`\`\`

---

### パスワードバリデーション欠如 - app/schemas/user/create.py:10

**問題**: パスワードに最低文字数制約がない

**現在のコード**:
\`\`\`python
class UserCreate(BaseModel):
    password: str
\`\`\`

**修正案**:
\`\`\`python
from pydantic import BaseModel, Field

class UserCreate(BaseModel):
    password: str = Field(..., min_length=8)  # 最低8文字
\`\`\`

## 🟢 低リスク（推奨）

### メールアドレスバリデーション - app/schemas/user/create.py:9

**推奨**: `EmailStr`を使用してメールアドレス形式を検証

**現在のコード**:
\`\`\`python
email: str
\`\`\`

**推奨コード**:
\`\`\`python
from pydantic import EmailStr

email: EmailStr
\`\`\`

## ✅ 問題なし

以下の項目は問題ありませんでした：

- パスワードハッシュ化: OK（bcrypt使用）
- JWT検証: OK（SECRET_KEYで署名検証）
- .envファイル: .gitignoreに含まれている
- CORS設定: 適切に設定されている
- ログ出力: 機密情報は含まれていない

## 📊 サマリー

- 🔴 高リスク: 2件
- 🟡 中リスク: 2件
- 🟢 低リスク: 1件
- ✅ 問題なし: 5件

## 次のステップ

1. **高リスク項目から修正**: SQLインジェクション、ハードコードされたシークレットを最優先で修正
2. **中リスク項目を確認**: 認証欠如、バリデーション欠如を修正
3. **低リスク項目を検討**: メールアドレスバリデーションなどを改善
4. **再チェック**: 修正後に再度 `/security-check` を実行

---

**生成者**: Claude Code `/security-check` スキル
**日時**: 2024-01-20 10:30:00
```

### 4. レポートを保存

`security-report.md`として保存し、ユーザーに通知します。

## 実行後の対応

### 高リスク項目（🔴）

**即座に修正**が必要です。SQLインジェクション、ハードコードされたシークレットなどは、本番環境で重大な被害を引き起こす可能性があります。

### 中リスク項目（🟡）

**要確認**です。認証欠如、バリデーション欠如などは、セキュリティホールになる可能性があります。

### 低リスク項目（🟢）

**推奨**です。メールアドレスバリデーションなどは、セキュリティを向上させるために推奨されます。

## 次のステップ

レポート生成後、ユーザーに以下を提案してください：

- **高リスク項目を修正**: 最優先で修正
- **パフォーマンスチェックも実行**: `/performance-check`スキルを実行
- **再チェック**: 修正後に再度 `/security-check` を実行して問題が解消されたことを確認
- **CI/CDに統合**: GitHub Actionsで自動実行するように設定

## CI/CDへの統合（オプション）

`.github/workflows/security-check.yml`を作成してCI/CDに統合することも可能です：

```yaml
name: Security Check

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run security check
        run: |
          # セキュリティチェックツール実行
          # 例: bandit, safety など
          pip install bandit safety
          bandit -r app/
          safety check
```
