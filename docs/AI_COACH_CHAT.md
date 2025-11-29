# AI Coach Chat Integration

## Overview

The AI Coach Chat feature provides an intelligent, context-aware fitness coaching chatbot integrated directly into the Fitness Agent app. The AI coach has access to:

- **Health Metrics**: HRV, heart rate, sleep, workouts
- **Goals**: User's fitness goals and progress
- **Readiness**: Current recovery and training readiness scores
- **Historical Data**: Trends and patterns over time

## Architecture

```
┌─────────────────┐
│  Flutter App    │
│  (ChatScreen)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ ChatApiService  │  ← HTTP Client
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  FastAPI Chat   │  /chat/messages
│     Router      │  /chat/sessions
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ AIChatService   │  ← OpenAI/Anthropic
└────────┬────────┘
         │
         ├──────────────────┐
         ▼                  ▼
┌──────────────┐    ┌──────────────┐
│  Database    │    │  AI Provider │
│  (Context)   │    │  (LLM API)   │
└──────────────┘    └──────────────┘
```

## Backend Components

### 1. Database Schema

Two new tables support chat functionality:

#### `chat_sessions`
```sql
CREATE TABLE chat_sessions (
    id INTEGER PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

#### `chat_messages`
```sql
CREATE TABLE chat_messages (
    id INTEGER PRIMARY KEY,
    session_id INTEGER NOT NULL,
    user_id TEXT NOT NULL,
    role TEXT NOT NULL,  -- 'user' or 'assistant'
    content TEXT NOT NULL,
    metadata TEXT,       -- JSON with context info
    created_at TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES chat_sessions(id)
);
```

### 2. AI Chat Service (`ai_chat_service.py`)

**Key Features**:
- Multi-provider support (OpenAI, Anthropic, or mock mode)
- Context retrieval from health/goals data
- System prompt generation with user context
- Conversation history management

**Methods**:
- `get_user_context(user_id, days=7)` - Fetch health data, goals, readiness
- `build_system_prompt(context)` - Create AI system prompt with context
- `generate_response(user_id, message, session_id, chat_history)` - Get AI response
- `_generate_mock_response(message, context)` - Development fallback

**Environment Variables**:
```env
AI_PROVIDER=openai              # or 'anthropic'
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini
ANTHROPIC_API_KEY=sk-ant-...
ANTHROPIC_MODEL=claude-3-5-sonnet-20241022
```

### 3. Chat Router (`routers/chat.py`)

**Endpoints**:

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/chat/sessions` | Create new chat session |
| `GET` | `/chat/sessions?user_id=X` | List user's sessions |
| `GET` | `/chat/sessions/{id}` | Get session details |
| `DELETE` | `/chat/sessions/{id}` | Delete session + messages |
| `POST` | `/chat/messages` | Send message, get AI response |
| `GET` | `/chat/messages/{session_id}` | Get all messages in session |
| `GET` | `/chat/context/{user_id}` | Debug: view user context |

**Example Request**:
```json
POST /chat/messages
{
  "user_id": "user-123",
  "message": "What should I train today?",
  "session_id": 1  // optional, creates new if omitted
}
```

**Example Response**:
```json
{
  "session_id": 1,
  "user_message": {
    "id": 42,
    "role": "user",
    "content": "What should I train today?",
    "created_at": "2025-11-16T10:30:00Z"
  },
  "assistant_message": {
    "id": 43,
    "role": "assistant",
    "content": "Your readiness looks good! You're recovered and ready for...",
    "metadata": {
      "model": "gpt-4o-mini",
      "tokens": 234,
      "context": "User has 2 active goal(s). Recent metrics: hrv, sleep. Readiness: 85%"
    },
    "created_at": "2025-11-16T10:30:05Z"
  }
}
```

## Frontend Components

### 1. Models (`chat_models.dart`)

```dart
class ChatSession {
  final int id;
  final String userId;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
}

class ChatMessage {
  final int? id;
  final int sessionId;
  final String role;  // "user" or "assistant"
  final String content;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
}

class SendMessageRequest {
  final String userId;
  final String message;
  final int? sessionId;
}
```

### 2. API Service (`chat_api_service.dart`)

```dart
class ChatApiService {
  Future<List<ChatSession>> getSessions(String userId);
  Future<ChatSession> createSession(String userId, {String? title});
  Future<List<ChatMessage>> getMessages(int sessionId, String userId);
  Future<SendMessageResponse> sendMessage(SendMessageRequest request);
  Future<void> deleteSession(int sessionId, String userId);
}
```

### 3. Chat Screen (`chat_screen.dart`)

**Features**:
- Message bubbles (user vs assistant styling)
- Auto-scroll to latest message
- Loading states during AI response
- Error handling with retry
- Empty state with suggested questions
- Info dialog explaining coach capabilities
- Timestamp formatting ("Just now", "5m ago", etc.)

**UI Elements**:
- AppBar with title and info button
- Message list with bubble design
- Text input field with send button
- Suggestion chips for quick questions
- Loading indicator during message send
- Error banner for failed requests

## Integration Steps

### Backend Setup

1. **Install Dependencies**:
```bash
cd applications/backend/python_fastapi_server
pip install -r requirements.txt  # includes openai, anthropic
```

2. **Set Environment Variables**:
```bash
export AI_PROVIDER=openai
export OPENAI_API_KEY=sk-...
export OPENAI_MODEL=gpt-4o-mini
```

3. **Initialize Database**:
```bash
python -c "from database import init_sqlite; init_sqlite()"
```

4. **Start Server**:
```bash
uvicorn main:app --reload
```

### Frontend Setup

1. **Add Package Dependency**:
```yaml
# In home_dashboard_ui/pubspec.yaml
dependencies:
  ai_coach_chat:
    path: ../ai_coach_chat
```

2. **Import and Navigate**:
```dart
import 'package:ai_coach_chat/ai_coach_chat.dart';

// Navigate to chat
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ChatScreen(userId: 'user-123'),
  ),
);
```

3. **Add Navigation Button** (already done in home_screen.dart):
```dart
AppBar(
  title: const Text('Rummel Fitness AI'),
  actions: [
    IconButton(
      icon: const Icon(Icons.chat_bubble_outline),
      tooltip: 'AI Coach',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(userId: 'user-123'),
          ),
        );
      },
    ),
  ],
)
```

## Usage Examples

### Basic Conversation Flow

1. User taps chat icon in home screen
2. ChatScreen opens with empty state
3. User types or taps suggestion: "What should I train today?"
4. ChatApiService sends request to backend
5. Backend:
   - Fetches user context (health metrics, goals, readiness)
   - Builds system prompt with context
   - Calls OpenAI/Anthropic API
   - Saves messages to database
6. Frontend displays AI response in assistant bubble
7. Conversation continues with full history context

### Sample Conversations

**Goal-Related Questions**:
```
User: Help me set a marathon goal
AI: Great! Let's set up a marathon goal. Based on your recent training...
```

**Training Advice**:
```
User: What should I train today?
AI: Your readiness is 85% - you're well recovered! Consider a quality...
```

**Recovery Analysis**:
```
User: How is my recovery looking?
AI: Your HRV has been averaging 55ms with good sleep at 7.5hrs...
```

**Metric Explanation**:
```
User: What does HRV mean?
AI: HRV (Heart Rate Variability) measures the variation in time between...
```

## Mock Mode for Development

If no AI provider is configured, the service automatically falls back to mock mode:

```python
def _generate_mock_response(self, message: str, context: Dict) -> str:
    # Returns contextual responses based on keywords
    if "goal" in message.lower():
        return "Based on your recent data, you're making solid progress..."
    elif "workout" in message.lower():
        readiness = context.get("readiness", 0.5)
        if readiness > 0.7:
            return "Your readiness looks good! You're recovered..."
    # ... more patterns
```

This allows full frontend development and testing without API keys.

## Testing

### Backend Tests

```bash
# Test chat endpoints
curl -X POST http://localhost:8000/chat/messages \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user-123",
    "message": "What should I train today?"
  }'

# Get user context for debugging
curl http://localhost:8000/chat/context/user-123

# List sessions
curl "http://localhost:8000/chat/sessions?user_id=user-123"
```

### Frontend Tests

```dart
testWidgets('Chat screen displays messages', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChatScreen(userId: 'test-user'),
    ),
  );
  
  expect(find.text('AI Fitness Coach'), findsOneWidget);
  expect(find.byIcon(Icons.send), findsOneWidget);
});
```

## Customization

### Adjust AI Behavior

Edit system prompt in `ai_chat_service.py`:

```python
def build_system_prompt(self, context: Dict[str, Any]) -> str:
    prompt = """You are an expert AI fitness coach...
    
    Your personality: [encouraging, data-driven, concise]
    Your expertise: [training, recovery, nutrition, goals]
    """
```

### Add New Context Data

Extend `get_user_context()`:

```python
# Add workout history
cur.execute("""
    SELECT type, AVG(duration) as avg_duration
    FROM workouts
    WHERE user_id = ? AND date >= ?
    GROUP BY type
""", (user_id, cutoff))
context["workouts"] = [dict(row) for row in cur.fetchall()]
```

### Change UI Styling

Modify bubble colors in `chat_screen.dart`:

```dart
color: isUser
    ? Theme.of(context).colorScheme.primary  // User bubble
    : Colors.grey.shade200,                   // AI bubble
```

## Performance Considerations

- **Context Caching**: User context is fetched per message (could cache for session)
- **Message Limiting**: Frontend loads last 50 messages by default
- **History Context**: Backend uses last 10 messages for AI context
- **Token Management**: Metadata tracks token usage per response
- **Database Indexing**: Indexes on user_id and session_id for fast queries

## Security & Privacy

- **User Isolation**: All queries filtered by user_id
- **Session Ownership**: Verified before message access/deletion
- **API Keys**: Stored in environment variables, never in code
- **Data Retention**: Consider implementing message pruning policy
- **Content Filtering**: AI providers have built-in safety filters

## Troubleshooting

### "No AI provider configured"
- Set `AI_PROVIDER` environment variable
- Install required package: `pip install openai` or `pip install anthropic`
- Verify API key is set

### "Failed to send message"
- Check backend server is running: `http://localhost:8000/docs`
- Verify database initialized: `SELECT * FROM chat_sessions;`
- Check API key validity

### "Target of URI doesn't exist: ai_coach_chat"
- Run `flutter pub get` in home_dashboard_ui package
- Verify ai_coach_chat package exists in correct path
- Check pubspec.yaml dependency path

### Messages not loading
- Verify session_id exists in database
- Check user_id matches between frontend and backend
- Look for errors in backend logs

## Future Enhancements

- [ ] Streaming responses (SSE) for real-time typing effect
- [ ] Voice input/output integration
- [ ] Multi-session management UI
- [ ] Chat export/sharing
- [ ] Scheduled coach check-ins
- [ ] Personalized coaching programs
- [ ] Integration with workout logging
- [ ] Context-aware suggestions during workouts
- [ ] Nutrition advice based on training load
- [ ] Recovery recommendations

## API Reference

Full API documentation available at:
```
http://localhost:8000/docs#/chat
```

Interactive testing via Swagger UI.

---

**Version**: 1.0  
**Last Updated**: November 16, 2025  
**Status**: ✅ Complete and functional
