class ApplicationConfig
  # Centralized configuration for the application
  
  # OpenAI Model Configuration
  DEFAULT_MODEL = 'gpt-4o-mini'  # Change this to switch models globally
  
  # Model-specific configurations
  MODEL_CONFIGS = {
    'gpt-3.5-turbo' => {
      max_tokens: 4096,
      temperature: 0.7,
      max_response_tokens: 1000,
      pricing: { input: 0.001, output: 0.002 }
    },
    'gpt-3.5-turbo-1106' => {
      max_tokens: 16385,
      temperature: 0.7,
      max_response_tokens: 1000,
      pricing: { input: 0.001, output: 0.002 }
    },
    'gpt-4' => {
      max_tokens: 8192,
      temperature: 0.7,
      max_response_tokens: 1000,
      pricing: { input: 0.03, output: 0.06 }
    },
    'gpt-4-1106-preview' => {
      max_tokens: 128000,
      temperature: 0.7,
      max_response_tokens: 1000,
      pricing: { input: 0.01, output: 0.03 }
    },
    'gpt-4o' => {
      max_tokens: 128000,
      temperature: 0.7,
      max_response_tokens: 1000,
      pricing: { input: 0.005, output: 0.015 }
    },
    'gpt-4o-mini' => {
      max_tokens: 128000,
      temperature: 0.7,
      max_response_tokens: 1000,
      pricing: { input: 0.00015, output: 0.0006 }
    }
  }.freeze
  
  # Configuration methods
  def self.current_model
    ENV['OPENAI_MODEL'] || DEFAULT_MODEL
  end
  
  def self.model_config(model = nil)
    model ||= current_model
    MODEL_CONFIGS[model] || MODEL_CONFIGS[DEFAULT_MODEL]
  end
  
  def self.token_limit(model = nil)
    model_config(model)[:max_tokens]
  end
  
  def self.temperature(model = nil)
    model_config(model)[:temperature]
  end
  
  def self.max_response_tokens(model = nil)
    model_config(model)[:max_response_tokens]
  end
  
  def self.pricing(model = nil)
    model_config(model)[:pricing]
  end
  
  # Token buffer for responses
  RESPONSE_TOKEN_BUFFER = 1000
  
  def self.available_tokens_for_history(model = nil)
    token_limit(model) - RESPONSE_TOKEN_BUFFER
  end
end
