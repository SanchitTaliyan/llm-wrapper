# Model Configuration Guide

## How to Change the OpenAI Model

The application now has centralized model configuration. You can change the model in one place and it will be reflected everywhere.

### Option 1: Change Default Model (Recommended)

Edit `/app/models/application_config.rb`:

```ruby
DEFAULT_MODEL = 'gpt-4o-mini'  # Change this line
```

Available models:
- `gpt-3.5-turbo`
- `gpt-3.5-turbo-1106` 
- `gpt-4`
- `gpt-4-1106-preview`
- `gpt-4o`
- `gpt-4o-mini`

### Option 2: Use Environment Variable

Set the `OPENAI_MODEL` environment variable:

```bash
# In your .env file
OPENAI_MODEL=gpt-4o-mini
```

Or when running the server:
```bash
OPENAI_MODEL=gpt-4o rails server
```

### Option 3: Per-Request Model

You can also specify the model when creating the OpenAI service:

```ruby
service = OpenaiService.new(model: 'gpt-4o')
```

## What Gets Updated Automatically

When you change the model, the following are automatically updated:
- ✅ API calls to OpenAI
- ✅ Token counting and limits
- ✅ Cost estimation
- ✅ History trimming logic
- ✅ Usage monitoring
- ✅ Temperature and response limits

## Model Configurations

Each model has its own configuration in `ApplicationConfig::MODEL_CONFIGS`:

- **Token limits**: Maximum context window
- **Temperature**: Creativity/randomness setting  
- **Max response tokens**: Maximum response length
- **Pricing**: Cost per 1K tokens for input/output

## Examples

### For Development (Cheap & Fast)
```ruby
DEFAULT_MODEL = 'gpt-4o-mini'  # Very cheap, 128K context
```

### For Production (Balanced)
```ruby
DEFAULT_MODEL = 'gpt-4o'       # Good quality, 128K context
```

### For High Quality (Expensive)
```ruby
DEFAULT_MODEL = 'gpt-4'        # Best quality, 8K context
```

## Cost Comparison (per 1K tokens)

| Model | Input Cost | Output Cost | Context Window |
|-------|------------|-------------|----------------|
| gpt-4o-mini | $0.00015 | $0.0006 | 128K |
| gpt-3.5-turbo | $0.001 | $0.002 | 4K |
| gpt-4o | $0.005 | $0.015 | 128K |
| gpt-4 | $0.03 | $0.06 | 8K |

**Recommendation**: Use `gpt-4o-mini` for development and cost-effective production usage.
