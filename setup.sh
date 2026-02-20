#!/bin/bash
# プロジェクト初期化スクリプト

echo "🚀 FastAPI Boilerplate Setup"
echo ""

# プロジェクト名を入力
read -p "Enter project name [my-fastapi-app]: " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-my-fastapi-app}

# Pythonバージョンの選択
echo ""
echo "Select Python version:"
echo "  1) Python 3.11 (recommended, stable)"
echo "  2) Python 3.12 (latest features)"
read -p "Enter choice [1]: " PY_CHOICE
PY_CHOICE=${PY_CHOICE:-1}

case $PY_CHOICE in
    1) PYTHON_VERSION="3.11" ;;
    2) PYTHON_VERSION="3.12" ;;
    *) echo "Invalid choice, using Python 3.11"; PYTHON_VERSION="3.11" ;;
esac

# 認証方式の選択
echo ""
echo "Select authentication method:"
echo "  1) JWT (recommended for APIs, token-based)"
echo "  2) Session (ID/password, cookie-based)"
echo "  3) OAuth2 (external providers - future)"
echo "  4) None (no authentication)"
read -p "Enter choice [1]: " AUTH_CHOICE
AUTH_CHOICE=${AUTH_CHOICE:-1}

case $AUTH_CHOICE in
    1) AUTH_METHOD="jwt" ;;
    2) AUTH_METHOD="login_password" ;;
    3) AUTH_METHOD="oauth2" ;;
    4) AUTH_METHOD="none" ;;
    *) echo "Invalid choice, using JWT"; AUTH_METHOD="jwt" ;;
esac

# データベースの選択
echo ""
echo "Select database:"
echo "  1) PostgreSQL (recommended for production)"
echo "  2) MySQL"
echo "  3) SQLite (development/prototype)"
read -p "Enter choice [1]: " DB_CHOICE
DB_CHOICE=${DB_CHOICE:-1}

case $DB_CHOICE in
    1) DB_TYPE="postgresql" ;;
    2) DB_TYPE="mysql" ;;
    3) DB_TYPE="sqlite" ;;
    *) echo "Invalid choice, using PostgreSQL"; DB_TYPE="postgresql" ;;
esac

# .envファイルの生成
echo ""
cp .env.example .env
echo "✅ Created .env file"

# 認証方式に応じた設定（AUTH_TYPEとして保存）
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/AUTH_TYPE=.*/AUTH_TYPE=$AUTH_METHOD/g" .env
else
    sed -i "s/AUTH_TYPE=.*/AUTH_TYPE=$AUTH_METHOD/g" .env
fi
echo "✅ Set authentication type: $AUTH_METHOD"

# データベースに応じた設定
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/DB_TYPE=.*/DB_TYPE=$DB_TYPE/g" .env
else
    sed -i "s/DB_TYPE=.*/DB_TYPE=$DB_TYPE/g" .env
fi
echo "✅ Set database type: $DB_TYPE"

# SECRET_KEYの生成
SECRET_KEY=$(openssl rand -hex 32)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/your-secret-key-here-change-in-production/$SECRET_KEY/g" .env
else
    # Linux
    sed -i "s/your-secret-key-here-change-in-production/$SECRET_KEY/g" .env
fi
echo "✅ Generated SECRET_KEY"

# プロジェクト名の置換（pyproject.toml、READMEなど）
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/boilerplate-fastapi/$PROJECT_NAME/g" pyproject.toml
    sed -i '' "s/requires-python = \">=3.11\"/requires-python = \">=$PYTHON_VERSION\"/g" pyproject.toml
else
    sed -i "s/boilerplate-fastapi/$PROJECT_NAME/g" pyproject.toml
    sed -i "s/requires-python = \">=3.11\"/requires-python = \">=$PYTHON_VERSION\"/g" pyproject.toml
fi
echo "✅ Updated project name and Python version"

# 選択に応じた不要ファイルの削除
echo ""
echo "📦 Cleaning up unused files..."

# 認証方式に応じて不要なファイルを削除
if [ "$AUTH_METHOD" != "jwt" ]; then
    rm -f app/auth/providers/jwt_provider.py 2>/dev/null
    echo "   Removed JWT provider"
fi
if [ "$AUTH_METHOD" != "login_password" ]; then
    rm -f app/auth/providers/login_password_provider.py 2>/dev/null
    echo "   Removed login/password provider"
fi
if [ "$AUTH_METHOD" == "none" ]; then
    rm -rf app/auth 2>/dev/null
    rm -f app/api/v1/endpoints/auth.py 2>/dev/null
    rm -f app/api/v1/endpoints/users.py 2>/dev/null
    rm -f app/models/user.py 2>/dev/null
    rm -rf app/schemas/user 2>/dev/null
    rm -rf app/schemas/token 2>/dev/null
    rm -f app/db/repositories/user.py 2>/dev/null
    rm -f app/utils/security.py 2>/dev/null
    echo "   Removed all authentication files"
fi

# データベースに応じてDocker Composeファイルを調整
if [ "$DB_TYPE" == "sqlite" ]; then
    # SQLiteの場合はPostgreSQLサービスを削除
    rm -f docker-compose.yml
    echo "   Removed PostgreSQL from docker-compose (using SQLite)"
elif [ "$DB_TYPE" == "mysql" ]; then
    # MySQLに変更
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/postgres:16-alpine/mysql:8.0/g' docker-compose.yml
        sed -i '' 's/POSTGRES_/MYSQL_ROOT_/g' docker-compose.yml
        sed -i '' 's/boilerplate_postgres/boilerplate_mysql/g' docker-compose.yml
        sed -i '' 's/pg_isready/mysqladmin ping/g' docker-compose.yml
    else
        sed -i 's/postgres:16-alpine/mysql:8.0/g' docker-compose.yml
        sed -i 's/POSTGRES_/MYSQL_ROOT_/g' docker-compose.yml
        sed -i 's/boilerplate_postgres/boilerplate_mysql/g' docker-compose.yml
        sed -i 's/pg_isready/mysqladmin ping/g' docker-compose.yml
    fi
    echo "   Configured MySQL in docker-compose"
fi

# uvのインストールチェック
echo ""
if ! command -v uv &> /dev/null; then
    echo "📦 Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# 仮想環境の作成（Pythonバージョン指定）
echo "📦 Creating virtual environment with Python $PYTHON_VERSION..."
uv venv --python $PYTHON_VERSION
source .venv/bin/activate

# 依存関係のインストール（選択に応じて）
echo "📦 Installing dependencies with uv..."

# 基本依存関係 + dev
INSTALL_EXTRAS="dev"

# 認証方式に応じた依存関係
if [ "$AUTH_METHOD" == "jwt" ]; then
    INSTALL_EXTRAS="$INSTALL_EXTRAS,jwt"
elif [ "$AUTH_METHOD" == "login_password" ]; then
    INSTALL_EXTRAS="$INSTALL_EXTRAS,session"
elif [ "$AUTH_METHOD" == "oauth2" ]; then
    INSTALL_EXTRAS="$INSTALL_EXTRAS,oauth2"
fi

# データベースに応じた依存関係
INSTALL_EXTRAS="$INSTALL_EXTRAS,$DB_TYPE"

# AI連携（オプション）
read -p "Include AI integration (Bedrock)? [y/N]: " INCLUDE_AI
if [[ "$INCLUDE_AI" =~ ^[Yy]$ ]]; then
    INSTALL_EXTRAS="$INSTALL_EXTRAS,ai"
fi

uv pip install -e ".[$INSTALL_EXTRAS]"
echo "✅ Installed: $INSTALL_EXTRAS"

# pre-commitフックのインストール
pre-commit install
echo "✅ Installed pre-commit hooks"

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Edit .env file with your settings"
echo "  2. docker-compose up -d postgres"
echo "  3. alembic upgrade head"
echo "  4. uvicorn app.main:app --reload"
echo ""
echo "API docs: http://localhost:8000/docs"
