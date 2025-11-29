#!/bin/bash
# AI Coach Chat Setup Script

set -e

echo "🤖 Setting up AI Coach Chat Integration..."
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "README.md" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

echo "📦 Step 1: Installing Python dependencies..."
cd applications/backend/python_fastapi_server
if [ -f "requirements.txt" ]; then
    pip install openai anthropic
    echo -e "${GREEN}✅ Python packages installed${NC}"
else
    echo "❌ requirements.txt not found"
    exit 1
fi
cd ../../..

echo ""
echo "🗄️  Step 2: Initializing database..."
cd applications/backend/python_fastapi_server
python3 << 'PYTHON'
from database import init_sqlite, get_db, get_cursor
init_sqlite()
print("Database initialized with chat tables")

# Verify tables exist
with get_db() as conn:
    cur = get_cursor(conn)
    cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name IN ('chat_sessions', 'chat_messages')")
    tables = [row[0] if isinstance(row, tuple) else row['name'] for row in cur.fetchall()]
    if len(tables) == 2:
        print(f"✅ Verified: {', '.join(tables)} tables created")
    else:
        print(f"⚠️  Warning: Only found {len(tables)} tables")
PYTHON
echo -e "${GREEN}✅ Database initialized${NC}"
cd ../../..

echo ""
echo "🔑 Step 3: Checking environment variables..."

# Check for .env file
ENV_FILE="applications/backend/python_fastapi_server/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Creating .env file..."
    cat > "$ENV_FILE" << 'EOF'
# AI Provider Configuration
AI_PROVIDER=openai
# AI_PROVIDER=anthropic

# OpenAI Configuration (if using openai)
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-4o-mini

# Anthropic Configuration (if using anthropic)
# ANTHROPIC_API_KEY=your_anthropic_api_key_here
# ANTHROPIC_MODEL=claude-3-5-sonnet-20241022

# Database
DATABASE_URL=sqlite:///fitness_dev.db

# Supabase (if using)
# SUPABASE_URL=https://your-project.supabase.co
# SUPABASE_KEY=your_service_role_key

# Security
SECRET_KEY=dev_secret_key_change_in_production
EOF
    echo -e "${YELLOW}⚠️  Created .env file - please update with your API keys${NC}"
else
    echo -e "${GREEN}✅ .env file exists${NC}"
fi

# Check if API keys are set
if grep -q "your_openai_api_key_here" "$ENV_FILE" 2>/dev/null || \
   grep -q "your_anthropic_api_key_here" "$ENV_FILE" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  API keys not configured - chat will run in mock mode${NC}"
    echo "   To use real AI:"
    echo "   1. Get API key from https://platform.openai.com or https://anthropic.com"
    echo "   2. Edit $ENV_FILE"
    echo "   3. Set OPENAI_API_KEY or ANTHROPIC_API_KEY"
else
    echo -e "${GREEN}✅ API keys configured${NC}"
fi

echo ""
echo "📱 Step 4: Setting up Flutter packages..."
cd applications/frontend/packages

# Install ai_coach_chat package dependencies
if [ -d "ai_coach_chat" ]; then
    cd ai_coach_chat
    if command -v flutter &> /dev/null; then
        flutter pub get
        echo -e "${GREEN}✅ ai_coach_chat package ready${NC}"
    else
        echo -e "${YELLOW}⚠️  Flutter not found - run 'flutter pub get' manually${NC}"
    fi
    cd ..
fi

# Update home_dashboard_ui
if [ -d "home_dashboard_ui" ]; then
    cd home_dashboard_ui
    if command -v flutter &> /dev/null; then
        flutter pub get
        echo -e "${GREEN}✅ home_dashboard_ui updated${NC}"
    fi
    cd ..
fi

cd ../../..

echo ""
echo "🎉 Setup Complete!"
echo ""
echo "Next steps:"
echo "1. Start the backend:"
echo "   cd applications/backend/python_fastapi_server"
echo "   uvicorn main:app --reload"
echo ""
echo "2. Test the chat endpoint:"
echo "   curl -X POST http://localhost:8000/chat/messages \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"user_id\": \"test-user\", \"message\": \"Hello coach!\"}'"
echo ""
echo "3. Run the Flutter app:"
echo "   cd applications/frontend/apps/mobile_app"
echo "   flutter run"
echo ""
echo "4. Tap the chat icon in the app's top-right corner!"
echo ""
echo "📚 Documentation: AI_COACH_CHAT.md"
echo ""
