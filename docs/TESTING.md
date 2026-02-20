# テストの書き方

このドキュメントでは、FastAPIボイラープレートプロジェクトでのテストの書き方を説明します。

## 📚 関連ドキュメント

- [../README.md](../README.md) - プロジェクト概要
- [../CLAUDE.md](../CLAUDE.md) - コアガイドライン

**開発環境とコーディング**
- [SETUP.md](SETUP.md) - 開発環境セットアップ
- [CODING_STANDARDS.md](CODING_STANDARDS.md) - コーディング規約

**テストと品質**
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

## 概要

このプロジェクトでは、**pytest**と**pytest-asyncio**を使用して非同期テストを記述します。

## テストクライアント

httpx >= 0.26.0を使用してください。

FastAPIの`TestClient`は内部でhttpxを使用しており、非同期テストに対応しています。

## 1. テストの配置

テストファイルは`tests/`ディレクトリに配置します。

```
tests/
├── conftest.py           # 共通フィクスチャ
└── test_api/
    ├── test_auth.py      # 認証エンドポイントのテスト
    └── test_users.py     # ユーザーエンドポイントのテスト
```

## 2. 非同期テストの書き方

**pytest-asyncio**を使用して非同期テストを記述します。

### 基本的なテスト

```python
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_create_user(client: AsyncClient):
    """ユーザー登録のテスト"""
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "test@example.com",
            "password": "password123",
            "full_name": "Test User"
        }
    )
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "test@example.com"
    assert "id" in data
```

## 3. フィクスチャの使用

フィクスチャを使用して、テストの準備と後処理を行います。

### 共通フィクスチャ（`tests/conftest.py`）

```python
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.fixture
async def client():
    """テスト用クライアント"""
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

@pytest.fixture
async def auth_client(client: AsyncClient):
    """認証済みクライアント"""
    # ユーザー登録
    await client.post("/api/v1/auth/register", json={
        "email": "test@example.com",
        "password": "password123",
        "full_name": "Test User"
    })

    # ログイン
    response = await client.post("/api/v1/auth/login", data={
        "username": "test@example.com",
        "password": "password123"
    })
    token = response.json()["access_token"]

    # トークンをヘッダーに設定
    client.headers["Authorization"] = f"Bearer {token}"
    yield client
```

### フィクスチャの使用例

```python
@pytest.mark.asyncio
async def test_get_current_user(auth_client: AsyncClient):
    """現在のユーザー取得のテスト"""
    response = await auth_client.get("/api/v1/users/me")
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "test@example.com"
```

## 4. テスト実行

### カバレッジ付きテスト実行

```bash
# カバレッジ付きテスト実行（推奨）
./bin/test.sh

# または直接
pytest tests/ -v --cov=app
```

### 特定のテストを実行

```bash
# 特定のテストファイルのみ実行
pytest tests/test_api/test_users.py -v

# 特定のテスト関数のみ実行
pytest tests/test_api/test_users.py::test_create_user -v
```

### オプション

- `-v`: 詳細な出力
- `-s`: print文の出力を表示
- `-x`: 最初の失敗で停止
- `--lf`: 前回失敗したテストのみ実行
- `--ff`: 前回失敗したテストを最初に実行

## 5. テストカバレッジ

### 目標カバレッジ

**80%以上**を目標としています。

### カバレッジレポート生成

```bash
# HTMLレポート生成
pytest tests/ --cov=app --cov-report=html

# ブラウザでレポート確認
open htmlcov/index.html
```

### カバレッジの確認

カバレッジが低い場合は、テストを追加してください。

## 6. テストのベストプラクティス

### ✅ 推奨事項

- **1テスト1アサーション**: 可能な限り、1つのテストで1つのことを検証
- **AAA パターン**: Arrange（準備）、Act（実行）、Assert（検証）
- **明確なテスト名**: テストが何を検証しているかが分かる名前
- **独立したテスト**: テスト間で依存関係を持たない

### 例

```python
@pytest.mark.asyncio
async def test_user_registration_returns_201_status(client: AsyncClient):
    # Arrange: テストデータの準備
    user_data = {
        "email": "newuser@example.com",
        "password": "password123",
        "full_name": "New User"
    }

    # Act: ユーザー登録
    response = await client.post("/api/v1/auth/register", json=user_data)

    # Assert: ステータスコードを検証
    assert response.status_code == 201
```

## 7. モックとスタブ

外部サービスへの依存を避けるため、モックを使用します。

### 例: 外部API呼び出しのモック

```python
from unittest.mock import AsyncMock, patch

@pytest.mark.asyncio
@patch('app.services.external_api.fetch_data')
async def test_external_api_call(mock_fetch_data, client: AsyncClient):
    # モックの戻り値を設定
    mock_fetch_data.return_value = {"data": "mocked data"}

    response = await client.get("/api/v1/external")
    assert response.status_code == 200
    assert response.json() == {"data": "mocked data"}
```

## まとめ

- **pytest-asyncio**で非同期テストを記述
- **フィクスチャ**でテストの準備と後処理
- **カバレッジ80%以上**を目標
- **AAA パターン**でテストを構造化
- **モック**で外部依存を排除
