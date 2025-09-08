# LittleBird Bot - Advanced ChatGPT Wrapper

A sophisticated chat application that wraps OpenAI's ChatGPT API, built with Ruby on Rails. This application provides enterprise-level features including token counting, usage monitoring, intelligent history management, and comprehensive analytics.

## 🚀 Features

### Core Chat Features
- ✅ **Multiple chat threads** - Create and manage separate conversations
- ✅ **Real-time messaging** - Send messages and receive AI responses instantly
- ✅ **Chat history persistence** - All conversations saved to database
- ✅ **Automatic chat titling** - Smart titles based on first message

### Advanced Token Management
- ✅ **Accurate token counting** - Using tiktoken for precise calculations
- ✅ **Intelligent history trimming** - Automatically manages context limits
- ✅ **Model-aware limits** - Supports GPT-3.5, GPT-4, GPT-4o, and GPT-4o-mini
- ✅ **Context preservation** - Always keeps recent messages for continuity

### Usage Monitoring & Analytics
- ✅ **Comprehensive usage dashboard** - Track tokens, costs, and activity
- ✅ **Daily/monthly reports** - Detailed usage breakdowns by time period
- ✅ **Top chats analysis** - Identify highest token-consuming conversations
- ✅ **Cost estimation** - Real-time pricing calculations
- ✅ **Per-chat analytics** - Individual chat usage statistics

### Enterprise Features
- ✅ **Centralized model configuration** - Change models globally with one setting
- ✅ **Error handling** - Graceful handling of API failures and limits
- ✅ **Usage limits monitoring** - Prevent context overflow errors
- ✅ **Responsive web UI** - Works on desktop and mobile
- ✅ **RESTful API** - Full JSON API for integration

## 📋 Requirements

- Ruby 3.3.9+ (specified in .ruby-version)
- Rails 8.0.2+
- SQLite3
- OpenAI API key
- tiktoken-ruby gem (for accurate token counting)

## 🛠️ Setup Instructions

### 1. Clone and Install Dependencies

```bash
cd littlebird_bot
bundle install
```

### 2. Database Setup

```bash
rails db:create
rails db:migrate
```

### 3. Configure OpenAI API Key

Create a `.env` file in the root directory:

```bash
echo "OPENAI_ACCESS_TOKEN=your_actual_openai_api_key_here" > .env
```

**Important:** Replace `your_actual_openai_api_key_here` with your real OpenAI API key from [OpenAI API Dashboard](https://platform.openai.com/api-keys).

### 4. Configure Model (Optional)

Edit `app/models/application_config.rb` to change the default model:

```ruby
DEFAULT_MODEL = 'gpt-4o-mini'  # Change this to switch models globally
```

Available models: `gpt-3.5-turbo`, `gpt-3.5-turbo-1106`, `gpt-4`, `gpt-4o`, `gpt-4o-mini`

### 5. Start the Server

```bash
rails server
```

The application will be available at `http://localhost:3000`

## 🔌 API Endpoints

### Chats
- `GET /chats` - List all chats (HTML/JSON)
- `GET /chats/:id` - Show specific chat with messages (HTML/JSON) 
- `POST /chats` - Create new chat
- `GET /chats/:id/usage` - Get usage statistics for specific chat

### Messages
- `POST /chats/:id/messages` - Send message and get AI response

### Usage Analytics
- `GET /usage` - Overall usage dashboard (HTML/JSON)
- `GET /usage/daily` - Daily usage statistics
- `GET /usage/monthly` - Monthly usage statistics  
- `GET /usage/top_chats` - Top chats by token usage

## 💻 Usage

### Web Interface
1. Visit `http://localhost:3000`
2. Click "New Chat" to create a conversation
3. Type your message and press Enter (or click Send)
4. View the AI response with token usage information
5. Access usage analytics via the "📊 Usage Stats" button
6. Continue conversations or manage multiple chat threads

### Usage Dashboard
- **Overview**: Total tokens, costs, and activity metrics
- **Daily Reports**: Day-by-day usage breakdown
- **Monthly Reports**: Monthly summaries with averages
- **Top Chats**: Highest token-consuming conversations
- **Per-Chat Analytics**: Individual chat usage details

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

# Get chat history with token usage
curl http://localhost:3000/chats/1.json

# Get usage analytics
curl http://localhost:3000/usage.json
curl http://localhost:3000/usage/daily.json
curl http://localhost:3000/usage/top_chats.json
```

## 🏗️ Architecture & Design Decisions

### Database Schema
```
chats
├── id (primary key)
├── title (string)
├── total_input_tokens (integer) - Cumulative input tokens
├── total_output_tokens (integer) - Cumulative output tokens  
├── total_tokens (integer) - Total tokens used
├── model_used (string) - Last model used for this chat
├── created_at (timestamp)
└── updated_at (timestamp)

messages
├── id (primary key) 
├── chat_id (foreign key -> chats.id)
├── content (text)
├── role (string: 'user' | 'assistant')
├── input_tokens (integer) - Tokens for this message
├── output_tokens (integer) - Tokens for this message
├── total_tokens (integer) - Total tokens for this message
├── created_at (timestamp)
└── updated_at (timestamp)
```

### Key Components

1. **Models**
   - `Chat`: Has many messages, token tracking, usage analytics, history trimming
   - `Message`: Belongs to chat, token counting, role validation
   - `ApplicationConfig`: Centralized model configuration and settings

2. **Services**
   - `OpenaiService`: OpenAI API integration with token management and error handling
   - `TokenCountingService`: Accurate token counting using tiktoken, cost estimation

3. **Controllers**
   - `ChatsController`: Chat CRUD operations with usage tracking
   - `MessagesController`: Message creation, AI response generation, token tracking
   - `UsageController`: Comprehensive analytics and reporting

4. **Views**
   - **Chat Views**: `index.html.erb`, `show.html.erb`, `create.html.erb`
   - **Usage Views**: `index.html.erb`, `daily.html.erb`, `monthly.html.erb`, `top_chats.html.erb`, `chat_usage.html.erb`
   - **Message Views**: `create.html.erb`
   - Responsive UI with modern styling and real-time updates

## ⚡ Technical Highlights

### Core Features
- **RESTful API design** with proper HTTP methods and status codes
- **Comprehensive error handling** for API failures, validation errors, and context limits
- **Automatic chat titling** based on first user message
- **Message ordering** and timestamps with token tracking
- **Responsive UI** that works on mobile and desktop
- **Environment variable** configuration for security

### Advanced Token Management
- **Accurate token counting** using tiktoken-ruby for precise calculations
- **Intelligent history trimming** to prevent context overflow
- **Model-aware token limits** supporting all major OpenAI models
- **Real-time cost estimation** with up-to-date pricing
- **Usage monitoring** with detailed analytics and reporting

### Enterprise Features
- **Centralized configuration** for easy model switching
- **Database relationships** with foreign key constraints and token tracking
- **Comprehensive analytics** with daily, monthly, and per-chat reporting
- **Context preservation** ensuring conversation continuity
- **Production-ready** error handling and logging

## 🧪 Testing the Application

1. Start the server: `rails server`
2. Visit `http://localhost:3000` 
3. Create a new chat
4. Send a test message like "Hello, can you help me with Ruby on Rails?"
5. Verify you receive an AI response with token usage information
6. Test the usage dashboard by clicking "📊 Usage Stats"
7. Explore daily, monthly, and top chats analytics
8. Test navigation between chat list and individual chats
9. Verify token counting and cost estimation accuracy

## 🚀 Production Considerations

For production deployment:
- Switch to PostgreSQL database for better performance
- Use Rails credentials instead of .env file for security
- Add authentication/authorization (Devise recommended)
- Implement rate limiting to prevent API abuse
- Add proper error pages and monitoring
- Set up comprehensive logging and alerting
- Add comprehensive test suite (RSpec recommended)
- Configure Redis for caching and background jobs
- Set up CI/CD pipeline for automated deployments
- Monitor token usage and costs with alerts

## 📊 Model Configuration

The application supports multiple OpenAI models with different capabilities:

| Model | Context Window | Input Cost/1K | Output Cost/1K | Best For |
|-------|----------------|---------------|----------------|----------|
| gpt-4o-mini | 128K | $0.00015 | $0.0006 | Development, cost-effective production |
| gpt-3.5-turbo | 4K | $0.001 | $0.002 | Simple tasks, legacy support |
| gpt-3.5-turbo-1106 | 16K | $0.001 | $0.002 | Medium complexity, longer context |
| gpt-4o | 128K | $0.005 | $0.015 | High-quality responses, large context |
| gpt-4 | 8K | $0.03 | $0.06 | Maximum quality, complex reasoning |

**Recommended**: Use `gpt-4o-mini` for most use cases - it provides excellent quality at 60x lower cost than GPT-4.

## 📝 Notes

- **Default Model**: gpt-4o-mini (cost-effective with 128K context)
- **Token Counting**: Uses tiktoken-ruby for accurate calculations
- **History Management**: Automatic trimming prevents context overflow
- **Database**: SQLite for development (easily switched to PostgreSQL)
- **Styling**: Modern CSS with responsive design
- **Error Handling**: Comprehensive error handling for all failure scenarios
