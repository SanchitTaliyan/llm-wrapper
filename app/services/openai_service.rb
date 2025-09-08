class OpenaiService
  def initialize(model: nil)
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])
    @model = model || ApplicationConfig.current_model
  end

  def current_model
    @model
  end

  def generate_response(chat, user_message_content = nil)
    trimmed_messages = prepare_messages_for_api(chat)
    
    if trimmed_messages.empty?
      Rails.logger.warn "No messages available for chat #{chat.id} after token trimming"
      return "I'm sorry, but the conversation history is too long. Please start a new chat."
    end
    
    input_tokens = TokenCountingService.count_chat_tokens(trimmed_messages, model: @model)
    
    Rails.logger.info "Chat #{chat.id}: Sending #{input_tokens} input tokens to #{@model}"
    
      response = @client.chat(
        parameters: {
          model: @model,
          messages: trimmed_messages,
          temperature: ApplicationConfig.temperature(@model),
          max_tokens: calculate_max_tokens(input_tokens)
        }
      )
    
    if response["error"]
      handle_api_error(response["error"], chat)
    else
      content = response.dig("choices", 0, "message", "content")
      usage = response.dig("usage")
      
      if usage
        Rails.logger.info "Chat #{chat.id}: API returned usage - input: #{usage['prompt_tokens']}, output: #{usage['completion_tokens']}, total: #{usage['total_tokens']}"
        
        chat.update_column(:model_used, @model)
        
        {
          content: content,
          usage: {
            input_tokens: usage['prompt_tokens'],
            output_tokens: usage['completion_tokens'],
            total_tokens: usage['total_tokens']
          }
        }
      else
        output_tokens = TokenCountingService.count_message_tokens(content, model: @model)
        
        {
          content: content,
          usage: {
            input_tokens: input_tokens,
            output_tokens: output_tokens,
            total_tokens: input_tokens + output_tokens
          }
        }
      end
    end
  rescue StandardError => e
    handle_service_error(e, chat)
  end
  
  def check_token_limits(chat)
    available_tokens = chat.total_available_tokens_for_history(@model)
    current_tokens, trimmed_messages = chat.messages_within_token_limit(@model)
    {
      model: @model,
      token_limit: ApplicationConfig.token_limit(@model),
      available_for_history: available_tokens,
      current_usage: current_tokens,
      within_limit: current_tokens <= available_tokens,
      messages_count: chat.messages.count,
      trimmed_messages_count: trimmed_messages.count
    }
  end
  
  def estimate_cost(chat)
    input_tokens = chat.total_input_tokens || 0
    output_tokens = chat.total_output_tokens || 0
    
    TokenCountingService.estimate_cost(
      input_tokens, 
      output_tokens, 
      model: @model
    )
  end

  private
  
  def prepare_messages_for_api(chat)
    _, messages_to_send = chat.messages_within_token_limit(@model)
    openai_messages = messages_to_send.map do |message|
      {
        role: message.role,
        content: message.content
      }
    end

    total_messages = chat.messages.count
    if messages_to_send.count < total_messages
      Rails.logger.info "Chat #{chat.id}: Trimmed #{total_messages - messages_to_send.count} messages to fit token limit"
    end
    
    openai_messages
  end
  
  def calculate_max_tokens(input_tokens)
    model_limit = TokenCountingService.total_token_limit_for_model(@model)
    max_response_tokens = ApplicationConfig.max_response_tokens(@model)
    available = model_limit - input_tokens - max_response_tokens
    
    [available, max_response_tokens].min.clamp(100, max_response_tokens)
  end
  
  def handle_api_error(error, chat)
    error_message = error["message"]
    error_type = error["type"]
    
    Rails.logger.error "OpenAI API error for chat #{chat.id}: #{error_type} - #{error_message}"
    
    case error_type
    when "insufficient_quota"
      "I'm sorry, but I've reached my usage limit. Please try again later or contact support."
    when "invalid_request_error"
      if error_message.include?("maximum context length")
        "The conversation has become too long. Please start a new chat to continue."
      else
        "I'm sorry, there was an issue with your request. Please try again."
      end
    when "rate_limit_exceeded"
      "I'm receiving too many requests right now. Please wait a moment and try again."
    when "context_length_exceeded"
      "The conversation history is too long. Please start a new chat."
    else
      "I'm sorry, I'm having trouble processing your request right now. Please try again later."
    end
  end
  
  def handle_service_error(error, chat)
    Rails.logger.error "OpenAI service error for chat #{chat.id}: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    
    if error.message.include?("context_length_exceeded") || error.message.include?("maximum context length")
      "The conversation has become too long. Please start a new chat to continue."
    else
      "I'm sorry, I'm having trouble processing your request right now. Please try again later."
    end
  end

  def self.api_key_present?
    ENV['OPENAI_ACCESS_TOKEN'].present?
  end
end
