# ChatGPT Wrapper - Rails Application

A minimal chat application that wraps OpenAI's ChatGPT API, built with Ruby on Rails. This application allows users to create multiple chat threads, send messages, and receive AI responses with full persistence.

## Features

- ✅ **View chat history** - Browse all your chat threads
- ✅ **Multiple chat threads** - Create and manage separate conversations
- ✅ **Start new chats** - Create new chat sessions
- ✅ **Send messages and receive responses** - Real-time conversation with ChatGPT
- ✅ **Simple web UI** - Clean, responsive interface for testing
- ✅ **SQLite database persistence** - All chats and messages are saved

## Requirements

- Ruby 3.3.9+ (specified in .ruby-version)
- Rails 8.0.2+
- SQLite3
- OpenAI API key

## Setup Instructions

### 1. Clone and Install Dependencies

```bash
cd littlebird_bot
bundle install
```

### 2. Database Setup

```bash
rails db:create
rails db:migrate
rails db:seed  # Optional: Creates sample data
```

### 3. Configure OpenAI API Key

Create a `.env` file in the root directory:

```bash
echo "OPENAI_ACCESS_TOKEN=your_actual_openai_api_key_here" > .env
```

**Important:** Replace `your_actual_openai_api_key_here` with your real OpenAI API key from [OpenAI API Dashboard](https://platform.openai.com/api-keys).

### 4. Start the Server

```bash
rails server
```

The application will be available at `http://localhost:3000`

## API Endpoints

### Chats
- `GET /chats` - List all chats (HTML/JSON)
- `GET /chats/:id` - Show specific chat with messages (HTML/JSON) 
- `POST /chats` - Create new chat

### Messages
- `POST /chats/:id/messages` - Send message and get AI response

## Usage

### Web Interface
1. Visit `http://localhost:3000`
2. Click "New Chat" to create a conversation
3. Type your message and press Enter (or click Send)
4. View the AI response
5. Continue the conversation or go back to view all chats

### API Usage
```bash
# Create a new chat
curl -X POST http://localhost:3000/chats.json \
  -H "Content-Type: application/json" \
  -d '{"chat": {"title": "My Chat"}}'

# Send a message
curl -X POST http://localhost:3000/chats/1/messages.json \
  -H "Content-Type: application/json" \
  -d '{"message": {"content": "Hello, ChatGPT!"}}'

# Get chat history
curl http://localhost:3000/chats/1.json
```

## Architecture & Design Decisions

### Database Schema
```
chats
├── id (primary key)
├── title (string)
├── created_at (timestamp)
└── updated_at (timestamp)

messages
├── id (primary key) 
├── chat_id (foreign key -> chats.id)
├── content (text)
├── role (string: 'user' | 'assistant')
├── created_at (timestamp)
└── updated_at (timestamp)
```

### Key Components

1. **Models**
   - `Chat`: Has many messages, includes validation and scopes
   - `Message`: Belongs to chat, validates role and content

2. **Services**
   - `OpenaiService`: Handles OpenAI API integration with error handling

3. **Controllers**
   - `ChatsController`: Manages chat CRUD operations 
   - `MessagesController`: Handles message creation and AI response generation

4. **Views**
   - Simple, responsive UI with Tailwind CSS
   - Real-time message updates with vanilla JavaScript

## Technical Highlights

- **RESTful API design** with proper HTTP methods and status codes
- **Error handling** for API failures and validation errors  
- **Automatic chat titling** based on first user message
- **Message ordering** and timestamps
- **Responsive UI** that works on mobile and desktop
- **Environment variable** configuration for security
- **Database relationships** with foreign key constraints

## Testing the Application

1. Start the server: `rails server`
2. Visit `http://localhost:3000` 
3. Create a new chat
4. Send a test message like "Hello, can you help me with Ruby on Rails?"
5. Verify you receive an AI response
6. Test navigation between chat list and individual chats

## Production Considerations

For production deployment:
- Switch to PostgreSQL database
- Use Rails credentials instead of .env file
- Add authentication/authorization
- Implement rate limiting
- Add proper error pages
- Set up monitoring and logging
- Add tests (RSpec recommended)

## Notes

- Uses GPT-3.5-turbo model (cost-effective for demo)
- Includes basic error handling for API failures  
- SQLite used for simplicity (easily switched to PostgreSQL)
- Tailwind CSS via CDN (should be properly installed for production)
