---
name: performance-check
description: >
  FastAPIアプリケーションのパフォーマンスレビュースキル。
  N+1クエリ、ブロッキングI/O、ページネーション欠如、接続プール設定を自動検出。
  修正提案を含むマークダウンレポートを生成。
---

# Performance Check Skill

FastAPIアプリケーションのパフォーマンスの問題を検出し、最適化提案を行います。

## 使い方

ユーザーが「パフォーマンスレビューして」「パフォーマンスチェックを実行して」「遅い箇所を探して」「最適化して」などと言った場合に実行します。

## チェック項目

### 1. N+1クエリ

**検出パターン**:
- ループ内でデータベースクエリを実行
- `selectinload()` または `joinedload()` の欠如
- リレーションシップを持つモデルで事前ロードがない

**✅ 最適化済み**:
```python
from sqlalchemy.orm import selectinload

# 1回のクエリでユーザーと投稿を取得
users = await db.execute(
    select(User)
    .options(selectinload(User.posts))  # N+1回避
    .limit(100)
)
```

**❌ N+1クエリ（問題あり）**:
```python
# 100件のユーザーに対して101回のクエリ
users = await db.execute(select(User).limit(100))
for user in users.scalars():
    posts = await db.execute(select(Post).where(Post.user_id == user.id))
    # ループ内でクエリ実行
```

**影響**: 100回のクエリが1回に削減（100倍高速化）

### 2. ページネーション欠如

**検出パターン**:
- `.all()` の使用（全件取得）
- `limit`/`offset` パラメータの欠如
- デフォルト値が大きすぎる（limit > 100）

**✅ ページネーション実装**:
```python
async def get_posts(
    skip: int = 0,
    limit: int = 20,  # デフォルト20件
    db: AsyncSession = Depends(get_db)
):
    if limit > 100:  # 最大100件に制限
        limit = 100
    result = await db.execute(select(Post).offset(skip).limit(limit))
    return result.scalars().all()
```

**❌ 全件取得（問題あり）**:
```python
async def get_posts(db: AsyncSession):
    result = await db.execute(select(Post))
    return result.scalars().all()  # 全件取得（スケーラビリティ問題）
```

**影響**: メモリ不足、レスポンス遅延の回避

### 3. ブロッキングI/O

**検出パターン**:
- 同期関数（`def`）の使用
- ファイルI/Oが `async` でない
- 外部API呼び出しが `httpx.AsyncClient` でない
- `time.sleep()` の使用（`asyncio.sleep()`を使うべき）

**✅ 非同期I/O**:
```python
import httpx

async def fetch_external_api():
    async with httpx.AsyncClient() as client:
        response = await client.get("https://api.example.com/data")
        return response.json()
```

**❌ ブロッキングI/O（問題あり）**:
```python
import requests

def fetch_external_api():  # 同期関数
    response = requests.get("https://api.example.com/data")
    return response.json()  # イベントループをブロック
```

**影響**: イベントループがブロックされ、他のリクエストを処理できない

### 4. 接続プール設定

**検出パターン**:
- `pool_size` と `max_overflow` の確認
- 推奨: `pool_size=10, max_overflow=20`（CPU数に応じて調整）
- `pool_pre_ping=True` の欠如（タイムアウト対策）

**✅ 適切な接続プール**:
```python
# app/db/session.py
engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=10,        # 同時接続数（CPU数 × 2が目安）
    max_overflow=20,     # 追加接続数
    pool_pre_ping=True,  # 接続確認
)
```

**❌ デフォルト設定（問題あり）**:
```python
engine = create_async_engine(settings.DATABASE_URL)
# pool_size=5（デフォルト）、max_overflow=10
```

**影響**: 接続プールが小さすぎると、リクエストが待機してスループットが低下

### 5. 非効率なクエリ

**検出パターン**:
- `count()` の使用（大量データで遅い）
- 不要な `JOIN` の検出
- `SELECT *` の使用（必要なカラムのみ取得すべき）

**✅ 効率的なクエリ**:
```python
# 必要なカラムのみ取得
result = await db.execute(
    select(User.id, User.email).where(User.is_active == True)
)
```

**❌ 非効率なクエリ（問題あり）**:
```python
# すべてのカラムを取得
result = await db.execute(select(User))  # SELECT *
```

**影響**: ネットワーク転送量とメモリ使用量の削減

## 実行フロー

### 1. プロジェクトルートで実行

```bash
/performance-check
```

### 2. Exploreエージェントを起動してスキャンを委譲

**IMPORTANT**: このスキルはメインのコンテキストを節約するため、Exploreエージェントにタスクを委譲します。

**Task tool の使用**:
- **subagent_type**: `Explore`
- **description**: `FastAPIパフォーマンスチェック実行`
- **prompt**: 以下の詳細な指示を渡す

**エージェントへの指示内容**:

```
FastAPIプロジェクトのパフォーマンスレビューを実行し、最適化提案を含むレポートを生成してください。

## スキャン対象ディレクトリ

以下のディレクトリを対象に全Pythonファイルをスキャン：
- app/api/v1/endpoints/
- app/db/repositories/
- app/db/session.py
- app/services/

## チェック項目

### 1. N+1クエリ（🔴 高影響）
- ループ内でデータベースクエリを実行
- selectinload() または joinedload() の欠如
- リレーションシップを持つモデルで事前ロードがない

### 2. ページネーション欠如（🟡 中影響）
- .all() の使用（全件取得）
- limit/offset パラメータの欠如
- デフォルト値が大きすぎる（limit > 100）

### 3. ブロッキングI/O（🔴 高影響）
- 同期関数（def）の使用
- 外部API呼び出しが httpx.AsyncClient でない
- time.sleep() の使用

### 4. 接続プール設定（🟡 中影響）
- pool_size と max_overflow の確認
- pool_pre_ping=True の欠如

### 5. 非効率なクエリ（🟢 低影響）
- SELECT * の使用
- 不要な JOIN の検出

## レポート生成

以下の形式でマークダウンレポート（performance-report.md）を生成：

# パフォーマンスレビューレポート

生成日時: [現在日時]

## 🔴 高影響（即修正）

### [問題タイトル] - [ファイルパス:行番号]

**問題**: [問題の説明]

**現在のコード**:
```python
[問題のあるコード]
```

**修正案**:
```python
[修正後のコード]
```

**影響**: [パフォーマンスへの影響]

---

## 🟡 中影響（要検討）

[同じ形式]

## 🟢 低影響（推奨）

[同じ形式]

## ✅ 最適化済み

以下の項目は最適化されています：
- [項目1]
- [項目2]

## 📊 サマリー

- 🔴 高影響: X件
- 🟡 中影響: Y件
- 🟢 低影響: Z件
- ✅ 最適化済み: W件

## 次のステップ

1. 高影響項目から修正
2. 中影響項目を検討
3. 低影響項目を検討
4. 再チェック: 修正後に再度 /performance-check を実行
5. 負荷テスト: locustやabで負荷テストを実行して効果を確認

---

**生成者**: Claude Code /performance-check スキル
**日時**: [現在日時]
```

レポートをプロジェクトルートに保存してください。
```

### 3. 結果サマリーをユーザーに表示

エージェントが完了したら、レポートのサマリー（高影響件数、中影響件数、低影響件数）をユーザーに表示し、`performance-report.md` の場所を案内します。

### 4. レポート生成（エージェントが実行）

マークダウンレポート（`performance-report.md`）を生成：

```markdown
# パフォーマンスレビューレポート

生成日時: 2024-01-20 10:30:00

## 🔴 高影響（即修正）

### N+1クエリ - app/api/v1/endpoints/users.py:30

**問題**: ループ内でクエリを実行

**現在のコード**:
\`\`\`python
users = await db.execute(select(User).limit(100))
for user in users.scalars():
    posts = await db.execute(select(Post).where(Post.user_id == user.id))
    # 100回のクエリが実行される
\`\`\`

**修正案**:
\`\`\`python
from sqlalchemy.orm import selectinload

users = await db.execute(
    select(User)
    .options(selectinload(User.posts))  # N+1回避
    .limit(100)
)
\`\`\`

**影響**: 100回のクエリが1回に削減（100倍高速化）

---

### ブロッキングI/O - app/services/external_api.py:15

**問題**: 同期的な外部API呼び出し

**現在のコード**:
\`\`\`python
import requests

def fetch_data():  # 同期関数
    response = requests.get("https://api.example.com/data")
    return response.json()
\`\`\`

**修正案**:
\`\`\`python
import httpx

async def fetch_data():  # 非同期関数
    async with httpx.AsyncClient() as client:
        response = await client.get("https://api.example.com/data")
        return response.json()
\`\`\`

**影響**: イベントループをブロックせず、他のリクエストを並行処理可能

## 🟡 中影響（要検討）

### ページネーション欠如 - app/db/repositories/post.py:15

**問題**: 全件取得（スケーラビリティ問題）

**現在のコード**:
\`\`\`python
async def get_posts(db: AsyncSession):
    result = await db.execute(select(Post))
    return result.scalars().all()  # 全件取得
\`\`\`

**修正案**:
\`\`\`python
async def get_posts(db: AsyncSession, skip: int = 0, limit: int = 20):
    if limit > 100:
        limit = 100
    result = await db.execute(select(Post).offset(skip).limit(limit))
    return result.scalars().all()
\`\`\`

**影響**: メモリ不足、レスポンス遅延の回避

---

### 接続プール設定 - app/db/session.py:10

**問題**: デフォルト設定（pool_size=5）

**現在のコード**:
\`\`\`python
engine = create_async_engine(settings.DATABASE_URL)
\`\`\`

**推奨コード**:
\`\`\`python
engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=10,        # CPU数 × 2
    max_overflow=20,     # 追加接続数
    pool_pre_ping=True,  # 接続確認
)
\`\`\`

**影響**: スループット向上

## 🟢 低影響（推奨）

### SELECT * の使用 - app/db/repositories/user.py:25

**推奨**: 必要なカラムのみ取得

**現在のコード**:
\`\`\`python
result = await db.execute(select(User))
\`\`\`

**推奨コード**:
\`\`\`python
result = await db.execute(select(User.id, User.email, User.full_name))
\`\`\`

**影響**: ネットワーク転送量とメモリ使用量の削減

## ✅ 最適化済み

以下の項目は最適化されています：

- 接続プール設定: OK (pool_size=10, max_overflow=20)
- 非同期処理: 全エンドポイントで使用
- ページネーション: ほとんどのエンドポイントで実装
- N+1クエリ回避: 主要なエンドポイントで`selectinload()`使用

## 📊 サマリー

- 🔴 高影響: 2件
- 🟡 中影響: 2件
- 🟢 低影響: 1件
- ✅ 最適化済み: 4件

## 次のステップ

1. **高影響項目から修正**: N+1クエリ、ブロッキングI/Oを最優先で修正
2. **中影響項目を検討**: ページネーション欠如、接続プール設定を改善
3. **低影響項目を検討**: SELECT * の使用など、さらなる最適化を検討
4. **再チェック**: 修正後に再度 `/performance-check` を実行
5. **負荷テスト**: `locust`や`ab`で負荷テストを実行して効果を確認

## パフォーマンス測定ツール

### 1. ロードテスト（Locust）

\`\`\`python
# locustfile.py
from locust import HttpUser, task, between

class FastAPIUser(HttpUser):
    wait_time = between(1, 3)

    @task
    def get_posts(self):
        self.client.get("/api/v1/posts/")

    @task
    def get_users(self):
        self.client.get("/api/v1/users/")
\`\`\`

実行:
\`\`\`bash
locust -f locustfile.py --host=http://localhost:8000
\`\`\`

### 2. プロファイリング（py-spy）

\`\`\`bash
# アプリケーション実行中にプロファイリング
py-spy top --pid <PID>
\`\`\`

---

**生成者**: Claude Code `/performance-check` スキル
**日時**: 2024-01-20 10:30:00
```

### 4. レポートを保存

`performance-report.md`として保存し、ユーザーに通知します。

## 実行後の対応

### 高影響項目（🔴）

**即座に修正**が必要です。N+1クエリ、ブロッキングI/Oなどは、スループットとレスポンス時間に大きな影響を与えます。

### 中影響項目（🟡）

**要検討**です。ページネーション欠如、接続プール設定などは、スケーラビリティに影響します。

### 低影響項目（🟢）

**推奨**です。SELECT * の使用などは、さらなる最適化のために推奨されます。

## パフォーマンス測定

### ロードテスト

修正前後でロードテストを実行し、効果を確認してください：

```bash
# Locustでロードテスト
pip install locust
locust -f locustfile.py --host=http://localhost:8000

# ブラウザで http://localhost:8089 を開く
# ユーザー数: 100
# スポーンレート: 10/秒
```

### プロファイリング

ボトルネックを特定するために、プロファイリングツールを使用してください：

```bash
# py-spyでプロファイリング
pip install py-spy
py-spy top --pid <PID>

# またはcProfileを使用
python -m cProfile -o profile.stats app/main.py
```

## 次のステップ

レポート生成後、ユーザーに以下を提案してください：

- **高影響項目を修正**: 最優先で修正
- **セキュリティチェックも実行**: `/security-check`スキルを実行
- **再チェック**: 修正後に再度 `/performance-check` を実行して問題が解消されたことを確認
- **ロードテスト**: 修正前後でロードテストを実行して効果を確認
- **CI/CDに統合**: GitHub Actionsで自動実行するように設定

## CI/CDへの統合（オプション）

`.github/workflows/performance-check.yml`を作成してCI/CDに統合することも可能です：

```yaml
name: Performance Check

on: [push, pull_request]

jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run performance check
        run: |
          # パフォーマンスチェック実行
          # 例: Locustでロードテスト
          pip install locust
          locust -f locustfile.py --headless --users 10 --spawn-rate 2 --run-time 30s --host=http://localhost:8000
```
