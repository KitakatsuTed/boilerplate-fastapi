# アーキテクチャ設計

このドキュメントでは、FastAPI Boilerplateのアーキテクチャ設計について詳しく説明します。

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
- [FAQ.md](FAQ.md) - よくある質問

---

## 目次

- [設計方針](#設計方針)
- [ディレクトリ構造の設計理由](#ディレクトリ構造の設計理由)
- [クリーンアーキテクチャの適用](#クリーンアーキテクチャの適用)
- [認証システムの設計](#認証システムの設計)
- [データベース層の設計](#データベース層の設計)
- [AI連携の抽象化レイヤー](#ai連携の抽象化レイヤー)

## 設計方針

このボイラープレートは、以下の原則に基づいて設計されています：

### 1. クリーンアーキテクチャ

- **関心の分離**: API層、ビジネスロジック層、データ層を明確に分離
- **依存性の方向**: 外側から内側へ（API → ビジネスロジック → データ層）
- **テスタビリティ**: 各層を独立してテスト可能

### 2. 型安全性

- **型ヒント**: すべての関数に型ヒントを適用
- **Pydanticスキーマ**: リクエスト/レスポンスの厳格なバリデーション
- **Generic型**: `BaseRepository[ModelType]`で型安全なCRUD操作

### 3. 拡張性

- **プロバイダーパターン**: 認証、データベース、AI連携を簡単に切り替え可能
- **依存性注入**: FastAPIのDIシステムを活用し、テストやモックを容易に
- **モジュール化**: 機能ごとにコードを分離し、不要な機能を削除しやすく

### 4. 保守性

- **1ファイル1クラスの原則**: コードの可読性と保守性を向上
- **Mixinを使用しない**: コードの明示性を優先
- **一貫したパターン**: scaffold.shで標準パターンを自動生成

## ディレクトリ構造の設計理由

```
app/
├── main.py                    # エントリーポイント（ミドルウェア、ルーター登録）
├── dependencies.py            # 共通依存性（get_db, get_auth_provider, get_current_user）
├── api/v1/                    # API層（バージョン管理）
│   ├── endpoints/             # エンドポイント（1ファイル1ルーター）
│   └── router.py              # ルート集約
├── auth/
│   └── providers/             # 認証プロバイダー（プロバイダーパターン）
├── core/                      # コアコンポーネント
│   ├── config.py              # 設定管理（Pydantic Settings）
│   ├── logger.py              # ロギング設定
│   ├── middlewares.py         # ミドルウェア
│   ├── handlers.py            # 例外ハンドラー
│   └── exceptions/            # カスタム例外（1ファイル1クラス）
├── db/                        # データベース層
│   ├── base.py                # SQLAlchemy Base
│   ├── session.py             # セッション管理（接続プール、非同期）
│   └── repositories/          # リポジトリパターン（1ファイル1クラス）
├── models/                    # ORMモデル（1ファイル1クラス）
├── schemas/                   # Pydanticスキーマ（1ファイル1クラス）
└── utils/                     # ユーティリティ（security.py等）
```

### なぜ`api/v1/`でバージョン管理するのか？

**理由**:
- APIのバージョンアップ時に既存のエンドポイントを破壊しない
- `v1`と`v2`を並行運用できる
- クライアント側が段階的に移行できる

**例**:
```
app/api/
├── v1/
│   ├── endpoints/
│   │   └── users.py   # GET /api/v1/users/
│   └── router.py
└── v2/
    ├── endpoints/
    │   └── users.py   # GET /api/v2/users/  （新しい仕様）
    └── router.py
```

### なぜ`endpoints/`に1ファイル1ルーターなのか？

**理由**:
- 関連するエンドポイントをグループ化（例: `auth.py`にログイン・登録・リフレッシュ）
- ファイルサイズが適度に保たれる（1000行を超えない）
- Gitコンフリクトが発生しにくい

**例**:
```python
# app/api/v1/endpoints/auth.py
router = APIRouter()

@router.post("/register")
async def register(...): ...

@router.post("/login")
async def login(...): ...

@router.post("/refresh")
async def refresh_token(...): ...
```

### なぜ1ファイル1クラスなのか？

**✅ メリット**:
- クラスの責任が明確になる
- ファイル名でクラスを探しやすい
- IDEのナビゲーションが快適
- Gitコンフリクトが発生しにくい

**❌ Mixinを使わない理由**:
- Mixinは継承チェーンを複雑にする
- タイムスタンプなどの共通フィールドは、直接定義しても数行なので問題ない
- コードの明示性を優先（「どこで定義されているか」が一目瞭然）

## クリーンアーキテクチャの適用

### レイヤー構成

```
┌─────────────────────────────────────┐
│  API層（app/api/v1/endpoints/）     │  ← HTTPリクエスト/レスポンス
├─────────────────────────────────────┤
│  ビジネスロジック層（repositories/） │  ← CRUD操作、ビジネスルール
├─────────────────────────────────────┤
│  データ層（models/, db/session.py）  │  ← データベースアクセス
└─────────────────────────────────────┘
```

### 依存性の方向

**原則**: 外側から内側への依存のみ

```python
# ✅ 良い例
# API層 → ビジネスロジック層
@router.get("/users/{user_id}")
async def get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
):
    repo = UserRepository(db)  # ビジネスロジック層に依存
    user = await repo.get_by_id(user_id)
    return user

# ビジネスロジック層 → データ層
class UserRepository(BaseRepository[User]):
    model = User  # データ層に依存
```

**❌ 悪い例**: 内側から外側への依存
```python
# データ層がAPI層に依存（アンチパターン）
class User(Base):
    def to_response(self) -> UserResponse:  # ❌ データ層がAPI層に依存
        ...
```

### 依存性注入（DI）の活用

**FastAPIのDIシステムを使う理由**:
- テストが容易（モックに差し替えやすい）
- グローバル変数を使わない（スレッドセーフ）
- コードの結合度が低い

**例**:
```python
# app/dependencies.py
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session

def get_auth_provider() -> BaseAuthProvider:
    if settings.AUTH_TYPE == "jwt":
        return JWTProvider()
    elif settings.AUTH_TYPE == "login_password":
        return LoginPasswordProvider()
    # ... 環境変数で切り替え

# エンドポイントで使用
@router.get("/users/me")
async def read_users_me(
    current_user: User = Depends(get_current_user),  # DIで注入
):
    return current_user
```

## 認証システムの設計

### 認証方式の用語定義

このプロジェクトでは、以下の認証方式をサポートしています：

- **`AUTH_TYPE=jwt`**: JWT (JSON Web Token) ベース認証
  - PyJWTを使用したトークンベース認証
  - ステートレス、APIに最適
  - アクセストークン（30分）+ リフレッシュトークン（7日）

- **`AUTH_TYPE=login_password`**: セッションベース認証
  - itsdangerousを使用したCookieベースのセッション管理
  - IDとパスワードでログイン
  - ステートフル、従来型のWebアプリに適している

- **`AUTH_TYPE=oauth2`**: OAuth 2.0外部認証（将来実装予定）
  - Google、GitHub等の外部プロバイダー認証

- **`AUTH_TYPE=none`**: 認証なし
  - 認証が不要なアプリケーション向け

### プロバイダーパターン

**設計思想**: 認証方式を簡単に切り替えられるようにする

```python
# 抽象基底クラス
class BaseAuthProvider(ABC):
    @abstractmethod
    async def create_token(self, user_id: int) -> str:
        pass

    @abstractmethod
    async def verify_token(self, token: str) -> Dict[str, Any] | None:
        pass

# JWT実装
class JWTProvider(BaseAuthProvider):
    async def create_token(self, user_id: int) -> str:
        # PyJWTでトークン生成
        ...

# セッション実装
class LoginPasswordProvider(BaseAuthProvider):
    async def create_token(self, user_id: int) -> str:
        # itsdangerousでセッショントークン生成
        ...
```

**切り替え方法**:
```bash
# .envファイルで切り替え
AUTH_TYPE=jwt  # または login_password, oauth2, none
```

### JWT認証フロー

```
┌──────────┐                    ┌──────────┐
│ クライアント │                    │ サーバー  │
└──────────┘                    └──────────┘
     │                                │
     │ POST /api/v1/auth/login       │
     │ { email, password }            │
     ├───────────────────────────────>│
     │                                │ ✓ パスワード検証
     │                                │ ✓ トークン生成（PyJWT）
     │                                │
     │ { access_token, refresh_token }│
     │<───────────────────────────────┤
     │                                │
     │ GET /api/v1/users/me          │
     │ Authorization: Bearer <token>  │
     ├───────────────────────────────>│
     │                                │ ✓ トークン検証
     │                                │ ✓ ユーザー取得
     │                                │
     │ { id, email, ... }             │
     │<───────────────────────────────┤
```

### セッション認証フロー

```
┌──────────┐                    ┌──────────┐
│ クライアント │                    │ サーバー  │
└──────────┘                    └──────────┘
     │                                │
     │ POST /api/v1/auth/login       │
     │ { email, password }            │
     ├───────────────────────────────>│
     │                                │ ✓ パスワード検証
     │                                │ ✓ セッショントークン生成
     │                                │
     │ Set-Cookie: session=<token>   │
     │<───────────────────────────────┤
     │                                │
     │ GET /api/v1/users/me          │
     │ Cookie: session=<token>        │
     ├───────────────────────────────>│
     │                                │ ✓ セッション検証
     │                                │ ✓ ユーザー取得
     │                                │
     │ { id, email, ... }             │
     │<───────────────────────────────┤
```

## データベース層の設計

### BaseRepositoryパターン

**設計思想**: 汎用CRUD操作を共通化し、型安全性を確保する

```python
from typing import Generic, TypeVar, Type, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession

ModelType = TypeVar("ModelType")

class BaseRepository(Generic[ModelType]):
    model: Type[ModelType]

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, id: int) -> ModelType | None:
        """IDで取得"""
        result = await self.db.execute(
            select(self.model).where(self.model.id == id)
        )
        return result.scalar_one_or_none()

    async def get_all(self, skip: int = 0, limit: int = 100) -> List[ModelType]:
        """全件取得（ページネーション付き）"""
        result = await self.db.execute(
            select(self.model).offset(skip).limit(limit)
        )
        return result.scalars().all()

    # ... その他のCRUD操作
```

**メリット**:
- コードの重複を削減（全リポジトリで共通のCRUD操作）
- 型安全（`UserRepository`は`User`型を返すことが保証される）
- カスタムメソッドを追加しやすい

**使用例**:
```python
# カスタムリポジトリ
class UserRepository(BaseRepository[User]):
    model = User

    async def get_by_email(self, email: str) -> User | None:
        """カスタムメソッド: メールアドレスで取得"""
        result = await self.db.execute(
            select(User).where(User.email == email)
        )
        return result.scalar_one_or_none()

# エンドポイントで使用
repo = UserRepository(db)
user = await repo.get_by_id(1)  # User型が返る
users = await repo.get_all(skip=0, limit=20)  # List[User]が返る
```

### 非同期SQLAlchemy

**なぜ非同期なのか？**:
- FastAPIは非同期フレームワーク
- I/O待機中に他のリクエストを処理できる（高スループット）
- `uvicorn`のワーカー数を増やさずにスケール可能

**接続プール設定**:
```python
# app/db/session.py
engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=10,        # 同時接続数（CPU数 × 2が目安）
    max_overflow=20,     # プールが満杯の場合の追加接続数
    pool_pre_ping=True,  # 接続確認（タイムアウト対策）
)
```

### データベース切り替え

**設計**: `DB_TYPE`環境変数で動的にURLを生成

```python
# app/core/config.py
@property
def DATABASE_URL(self) -> str:
    if self.DB_TYPE == "postgresql":
        return f"postgresql+asyncpg://..."
    elif self.DB_TYPE == "mysql":
        return f"mysql+aiomysql://..."
    elif self.DB_TYPE == "sqlite":
        return f"sqlite+aiosqlite://..."
    else:
        raise ValueError(f"Unknown DB_TYPE: {self.DB_TYPE}")
```

**メリット**:
- `.env`を変更するだけで切り替え可能
- 開発環境ではSQLite、本番ではPostgreSQLなどの使い分けが容易

## AI連携の抽象化レイヤー

**設計思想**: 複数のAIプロバイダーに対応できるように抽象化

```python
# app/services/ai/base.py
class AIProviderBase(ABC):
    @abstractmethod
    async def generate(self, prompt: str, **kwargs) -> str:
        """テキスト生成"""
        pass

    @abstractmethod
    async def generate_stream(self, prompt: str, **kwargs) -> AsyncGenerator[str, None]:
        """ストリーミング生成"""
        pass

# app/services/ai/bedrock.py
class BedrockProvider(AIProviderBase):
    async def generate(self, prompt: str, **kwargs) -> str:
        # boto3でBedrock Runtime呼び出し
        ...

# app/services/ai/openai.py（将来）
class OpenAIProvider(AIProviderBase):
    async def generate(self, prompt: str, **kwargs) -> str:
        # OpenAI API呼び出し
        ...
```

**切り替え方法**:
```bash
# .envファイルで切り替え
AI_PROVIDER=bedrock  # または openai, anthropic, gemini
```

**メリット**:
- 将来的に別のAIプロバイダーに切り替えやすい
- テストでモックプロバイダーに差し替えやすい

## まとめ

このアーキテクチャ設計により、以下が実現されます：

- **型安全性**: 型ヒントとPydanticスキーマによる厳格なバリデーション
- **テスタビリティ**: 依存性注入により、各層を独立してテスト可能
- **拡張性**: プロバイダーパターンにより、認証・データベース・AIを簡単に切り替え
- **保守性**: 1ファイル1クラスの原則により、コードの責任が明確

詳細なガイドラインは以下を参照してください：

- [../CLAUDE.md](../CLAUDE.md) - プロジェクトのコアガイドライン
- [SETUP.md](SETUP.md) - 開発環境セットアップ
- [TESTING.md](TESTING.md) - テスト詳細
- [SECURITY.md](SECURITY.md) - セキュリティ対策
- [PERFORMANCE.md](PERFORMANCE.md) - パフォーマンス最適化
