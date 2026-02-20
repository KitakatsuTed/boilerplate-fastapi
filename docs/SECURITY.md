# セキュリティ対策

このドキュメントでは、FastAPIボイラープレートプロジェクトで採用しているセキュリティ対策を説明します。OWASP Top 10に準拠したセキュリティベストプラクティスを実装しています。

## 📚 関連ドキュメント

- [../README.md](../README.md) - プロジェクト概要
- [../CLAUDE.md](../CLAUDE.md) - コアガイドライン

**開発環境とコーディング**
- [SETUP.md](SETUP.md) - 開発環境セットアップ
- [CODING_STANDARDS.md](CODING_STANDARDS.md) - コーディング規約

**テストと品質**
- [TESTING.md](TESTING.md) - テストの書き方

**データベースとパフォーマンス**
- [MIGRATIONS.md](MIGRATIONS.md) - マイグレーション
- [PERFORMANCE.md](PERFORMANCE.md) - パフォーマンス最適化

**ツールとデプロイ**
- [TOOLING.md](TOOLING.md) - Claude Codeスキルとscaffold.sh
- [FAQ.md](FAQ.md) - よくある質問

**アーキテクチャ**
- [ARCHITECTURE.md](ARCHITECTURE.md) - アーキテクチャ設計

---

## 概要

このプロジェクトでは、以下のセキュリティ対策を実装しています：

1. SQLインジェクション対策
2. パスワードハッシュ化
3. JWT署名検証
4. 認証エンドポイントの保護
5. CORS設定
6. 環境変数管理

## 1. SQLインジェクション対策

SQLインジェクション攻撃を防ぐため、**SQLAlchemyのORM**を使用します。生SQL文字列は使用しません。

### ✅ 良い例（SQLAlchemyのORM）

```python
# ORM使用（安全）
result = await db.execute(
    select(User).where(User.id == user_id)
)
```

### ❌ 悪い例（生SQL文字列）

```python
# 生SQL文字列（危険）
query = f"SELECT * FROM users WHERE id = {user_id}"  # ❌ SQLインジェクションの危険
result = await db.execute(text(query))
```

## 2. パスワードハッシュ化

パスワードは**必ずbcryptでハッシュ化**します。平文で保存しません。

### パスワードハッシュ化

```python
from app.utils.security import hash_password, verify_password

# ユーザー登録時
hashed_password = hash_password(plain_password)
user = User(email=email, hashed_password=hashed_password)

# ログイン時
if not verify_password(plain_password, user.hashed_password):
    raise UnauthorizedError("Invalid credentials")
```

### bcryptの仕組み

- **ソルト**を自動的に生成
- **コストファクター**により計算量を調整
- **レインボーテーブル攻撃**に耐性

## 3. JWT署名検証

JWTトークンは**SECRET_KEYで署名**し、改ざんを防ぎます。

### SECRET_KEYの管理

- `.env`ファイルで設定（Gitにコミットしない）
- 本番環境では環境変数またはシークレットマネージャーで管理
- `openssl rand -hex 32`で生成

### 例: .env

```bash
SECRET_KEY=your-secret-key-here-must-be-at-least-32-characters
```

### 例: JWT生成と検証

```python
from app.utils.security import create_access_token, verify_token

# トークン生成
access_token = create_access_token(data={"sub": user.email})

# トークン検証
payload = verify_token(token)
email = payload.get("sub")
```

## 4. 認証が必要なエンドポイント

保護が必要なエンドポイントには、**`get_current_user`依存性を必ず追加**します。

### 例: 認証必須エンドポイント

```python
from app.dependencies import get_current_user

@router.delete("/posts/{post_id}")
async def delete_post(
    post_id: int,
    current_user: User = Depends(get_current_user),  # ✅ 認証必須
    db: AsyncSession = Depends(get_db),
):
    # 認証されたユーザーのみアクセス可能
    post = await repo.get_by_id(post_id)

    # 所有者チェック
    if post.user_id != current_user.id:
        raise ForbiddenError("You are not the owner of this post")

    await repo.delete_by_id(post_id)
```

## 5. CORS設定

クロスオリジンリクエストを適切に制限します。

### 例: CORS設定（app/main.py）

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # 本番環境では適切に設定
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 本番環境での設定

```python
# 本番環境では特定のオリジンのみ許可
allow_origins=[
    "https://your-production-domain.com",
    "https://your-admin-domain.com"
]
```

## 6. 環境変数管理

機密情報は環境変数で管理し、Gitにコミットしません。

### .envファイル

```bash
# データベース
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/fastapi_db

# JWT
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# セッション（session認証の場合）
SESSION_SECRET_KEY=your-session-secret-key-here
```

### .gitignore

```bash
# .gitignoreに追加
.env
.env.local
.env.*.local
```

## 7. CSRF（Cross-Site Request Forgery）対策

CSRF攻撃を防ぐため、以下の対策を実装します。

### JWT認証の場合

JWT認証を使用する場合、トークンをリクエストヘッダーに含めることでCSRF攻撃を防ぎます。

**✅ 安全な例**:
```javascript
// フロントエンド（React/Next.js等）
const token = localStorage.getItem('access_token');

fetch('http://localhost:8000/api/v1/posts', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,  // ヘッダーに含める
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ title: 'New Post', content: '...' }),
});
```

**重要**: Cookieにトークンを保存する場合は、`HttpOnly`、`Secure`、`SameSite`属性を設定します。

### セッション認証の場合

セッション認証（Cookieベース）を使用する場合、CSRFトークンを実装する必要があります。

**実装例（FastAPI + itsdangerous）**:

```python
from itsdangerous import URLSafeTimedSerializer

# CSRFトークン生成
serializer = URLSafeTimedSerializer(settings.SESSION_SECRET_KEY)
csrf_token = serializer.dumps({"user_id": user.id})

# フロントエンドに返却
return {"csrf_token": csrf_token}
```

**フロントエンド（フォーム送信時）**:
```html
<form action="/api/v1/posts" method="POST">
  <input type="hidden" name="csrf_token" value="{{ csrf_token }}">
  <!-- フォームフィールド -->
</form>
```

**バックエンド（検証）**:
```python
from fastapi import Form, HTTPException

@router.post("/posts/")
async def create_post(
    csrf_token: str = Form(...),
    title: str = Form(...),
):
    # CSRFトークン検証
    try:
        serializer.loads(csrf_token, max_age=3600)  # 1時間有効
    except Exception:
        raise HTTPException(status_code=403, detail="Invalid CSRF token")

    # 処理を続行
    ...
```

### ベストプラクティス

- **JWT認証**: ヘッダーに含め、Cookieには保存しない（またはHttpOnly + Secure + SameSite設定）
- **セッション認証**: CSRFトークンを必ず実装
- **SameSite属性**: `SameSite=Lax` または `SameSite=Strict` を設定

## 8. XSS（Cross-Site Scripting）対策

XSS攻撃を防ぐため、入力バリデーションとエスケープ処理を実装します。

### Pydantic v2バリデーション

Pydantic v2スキーマを使用して、すべての入力を検証します。

**✅ 安全な例**:
```python
from pydantic import BaseModel, Field, field_validator

class PostCreate(BaseModel):
    title: str = Field(..., max_length=200)
    content: str = Field(..., max_length=10000)

    @field_validator('title', 'content')
    @classmethod
    def sanitize_html(cls, v):
        # HTMLタグを含む場合は拒否（オプション）
        if '<script>' in v.lower() or '<iframe>' in v.lower():
            raise ValueError('HTML tags are not allowed')
        return v
```

### HTMLエスケープ

HTMLを返却する場合（テンプレートエンジン使用時）、必ずエスケープ処理を行います。

**Jinja2テンプレートの場合**:
```html
<!-- 自動エスケープされる -->
<p>{{ post.title }}</p>

<!-- エスケープしない場合（危険）-->
<p>{{ post.title | safe }}</p>  <!-- ❌ 危険 -->
```

### JSON APIの場合

FastAPIはデフォルトでJSONレスポンスを返すため、ブラウザ側でのレンダリング時にエスケープ処理が必要です。

**フロントエンド（React/Next.js）**:
```jsx
// Reactは自動的にエスケープ
<div>{post.title}</div>  // 安全

// dangerouslySetInnerHTMLは避ける
<div dangerouslySetInnerHTML={{__html: post.content}} />  // ❌ 危険
```

### ベストプラクティス

- **すべての入力をPydanticで検証**
- **HTMLタグを含む入力を拒否**（必要に応じて）
- **Content-Security-Policy（CSP）ヘッダー設定**（オプション）

## 9. OWASP Top 10への対応

| OWASP Top 10                     | 対策                                   |
|----------------------------------|----------------------------------------|
| A01:2021 – Broken Access Control | 認証・認可の実装（`get_current_user`） |
| A02:2021 – Cryptographic Failures| bcryptによるパスワードハッシュ化       |
| A03:2021 – Injection             | SQLAlchemy ORM使用、XSS対策            |
| A04:2021 – Insecure Design       | クリーンアーキテクチャ採用             |
| A05:2021 – Security Misconfiguration | 環境変数管理、CORS設定、HTTPS/TLS強制 |
| A06:2021 – Vulnerable Components | 定期的な依存関係更新、脆弱性スキャン   |
| A07:2021 – Identification and Authentication Failures | JWT署名検証、パスワードポリシー、CSRF対策 |
| A08:2021 – Software and Data Integrity Failures | Alembicマイグレーション管理 |
| A09:2021 – Security Logging and Monitoring Failures | 構造化ロギング（標準出力） |
| A10:2021 – Server-Side Request Forgery (SSRF) | 外部リクエストの検証 |

## 10. HTTPS/TLS強制

本番環境では、必ずHTTPSを使用します。

### 開発環境

開発環境ではHTTPで問題ありませんが、本番環境に近い環境でテストする場合はHTTPSを使用します。

### 本番環境

本番環境では、以下の方法でHTTPSを強制します：

1. **リバースプロキシでHTTPS終端**（推奨）
   - ロードバランサー、nginx、Cloudflare等でHTTPSを終端
   - アプリケーションサーバーへはHTTPで転送
   - HTTPからHTTPSへのリダイレクトを設定

2. **アプリケーションサーバーで直接HTTPS**
   - SSL証明書をアプリケーションサーバーに配置
   - Uvicornで直接HTTPSを処理

### ローカル開発でHTTPSをテストする場合

```bash
# 自己署名証明書生成
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

# Uvicorn起動
uvicorn app.main:app --ssl-keyfile=key.pem --ssl-certfile=cert.pem --host 0.0.0.0 --port 8443
```

### HSTSヘッダー設定

HSTS（HTTP Strict Transport Security）ヘッダーを設定して、HTTPSを強制します。

**app/main.py**:
```python
from fastapi import FastAPI

app = FastAPI()

# 本番環境のみ有効化
if settings.ENVIRONMENT == "production":
    @app.middleware("http")
    async def add_hsts_header(request, call_next):
        response = await call_next(request)
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        return response
```

### ベストプラクティス

- **本番環境では必ずHTTPSを使用**
- **HTTPからHTTPSへリダイレクト**（リバースプロキシで設定）
- **HSTSヘッダーを設定**（1年間有効、includeSubDomains推奨）
- **SSL証明書は信頼できる認証局から取得**（Let's Encrypt等の無料証明書も可）

**注意**: 具体的なHTTPS設定方法は、使用するインフラ（ロードバランサー、nginx、Cloudflare等）によって異なります。詳細は使用するインフラのドキュメントを参照してください。

## 11. パスワードポリシー

強力なパスワードを強制して、ブルートフォース攻撃を防ぎます。

### Pydantic バリデーション

```python
from pydantic import BaseModel, Field, field_validator, EmailStr
import re

class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=100)

    @field_validator('password')
    @classmethod
    def validate_password_strength(cls, v):
        # 最低8文字
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')

        # 大文字を含む
        if not re.search(r'[A-Z]', v):
            raise ValueError('Password must contain at least one uppercase letter')

        # 小文字を含む
        if not re.search(r'[a-z]', v):
            raise ValueError('Password must contain at least one lowercase letter')

        # 数字を含む
        if not re.search(r'\d', v):
            raise ValueError('Password must contain at least one digit')

        # 記号を含む（オプション）
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', v):
            raise ValueError('Password must contain at least one special character')

        return v
```

### パスワードポリシーのレベル

**基本レベル**（推奨）:
- 最低8文字
- 大文字・小文字・数字を含む

**高セキュリティレベル**:
- 最低12文字
- 大文字・小文字・数字・記号を含む
- よくあるパスワードを拒否（"password123"等）

### よくあるパスワードチェック

```python
COMMON_PASSWORDS = [
    "password", "12345678", "qwerty", "abc123", "password123",
    "admin", "letmein", "welcome", "monkey", "1234567890"
]

@field_validator('password')
@classmethod
def check_common_passwords(cls, v):
    if v.lower() in COMMON_PASSWORDS:
        raise ValueError('This password is too common')
    return v
```

### ベストプラクティス

- **最低8文字以上**（NIST SP 800-63B推奨）
- **大文字・小文字・数字を含む**
- **よくあるパスワードを拒否**
- **パスワード履歴チェック**（オプション、DB保存必要）

## 12. 脆弱性スキャン

依存関係の脆弱性を定期的にスキャンします。

### Claude Codeスキル（推奨）

```bash
/vulnerability-scan
```

詳細は [TOOLING.md](TOOLING.md) を参照してください。

### 手動実行

#### bandit（Pythonコード静的解析）

```bash
# インストール
pip install bandit

# 実行
bandit -r app/ -f json -o bandit-report.json
```

#### safety（依存関係脆弱性スキャン）

```bash
# インストール
pip install safety

# 実行
safety check --json > safety-report.json
```

#### pip-audit（依存関係脆弱性スキャン）

```bash
# インストール
pip install pip-audit

# 実行
pip-audit --format=json > pip-audit-report.json
```

### CI/CDへの統合

`.github/workflows/security-scan.yml`:
```yaml
name: Vulnerability Scan

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          pip install bandit safety pip-audit
      - name: Run bandit
        run: bandit -r app/
      - name: Run safety
        run: safety check
      - name: Run pip-audit
        run: pip-audit
```

### ベストプラクティス

- **毎週実行**（ローカル開発）
- **CI/CDで自動実行**（プルリクエスト時）
- **依存関係を定期的に更新**（月1回）

## セキュリティチェックリスト

### 開発時

- [ ] SQLAlchemy ORMを使用（生SQL文字列を使わない）
- [ ] パスワードをbcryptでハッシュ化
- [ ] SECRET_KEYを`.env`ファイルで管理
- [ ] 認証が必要なエンドポイントに`get_current_user`を追加
- [ ] CORS設定を適切に設定
- [ ] CSRFトークン検証（セッション認証の場合）
- [ ] XSS対策（Pydanticバリデーション、HTMLエスケープ）
- [ ] パスワードポリシー実装（8文字以上、大文字・小文字・数字）

### デプロイ前

- [ ] `.env`ファイルが`.gitignore`に含まれている
- [ ] 本番環境のSECRET_KEYが十分に強力（32文字以上）
- [ ] CORS設定が本番環境に適している
- [ ] HTTPS/TLS強制（リバースプロキシで設定）
- [ ] HSTSヘッダー設定
- [ ] 環境変数が適切に管理されている（環境変数、シークレットマネージャー等）

### セキュリティレビュー

- [ ] `/security-check`スキルでセキュリティレビュー実行
- [ ] `/vulnerability-scan`スキルで脆弱性スキャン実行
- [ ] 依存関係の更新確認

## 参考資料

- [OWASP Top 10](https://owasp.org/Top10/)
- [FastAPI Security](https://fastapi.tiangolo.com/tutorial/security/)
- [SQLAlchemy Security](https://docs.sqlalchemy.org/en/20/faq/security.html)

## 次のステップ

セキュリティ対策を実装したら：

- [TOOLING.md](TOOLING.md) - `/security-check`スキルでセキュリティレビュー
- [TESTING.md](TESTING.md) - セキュリティテストの実装
