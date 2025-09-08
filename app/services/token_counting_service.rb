class TokenCountingService
  def self.encoding_for_model(model)
    @encodings ||= {}
    @encodings[model] ||= begin
      Tiktoken.encoding_for_model(model)
    rescue => e
      Rails.logger.warn "Failed to get encoding for model #{model}: #{e.message}. Using cl100k_base."
      Tiktoken.get_encoding('cl100k_base') # check this encoding
    end
  end

  def self.count_message_tokens(content, model: 'gpt-3.5-turbo')
    return 0 if content.blank?
    
    begin
      encoding = encoding_for_model(model)
      encoding.encode(content).length
    rescue => e
      Rails.logger.warn "Token counting failed: #{e.message}. Using fallback."
      fallback_token_count(content)
    end
  end

  def self.count_chat_tokens(messages, model: 'gpt-3.5-turbo')
    return 0 if messages.empty?
    
    begin
      encoding = encoding_for_model(model)
      tokens_per_message = message_overhead_for_model(model)
      num_tokens = 0
      
      messages.each do |message|
        num_tokens += tokens_per_message
        
        # Count tokens for role and content (message format)
        num_tokens += encoding.encode(message[:role].to_s).length
        num_tokens += encoding.encode(message[:content].to_s).length
      end
      
      num_tokens += 3
      
      num_tokens
    rescue => e
      Rails.logger.warn "Chat token counting failed: #{e.message}. Using fallback."
      fallback_chat_token_count(messages)
    end
  end

  # Estimate cost based on token usage (prices in USD per 1K tokens)
  def self.estimate_cost(input_tokens, output_tokens, model: 'gpt-3.5-turbo')
    pricing = model_pricing(model)
    
    input_cost = (input_tokens / 1000.0) * pricing[:input]
    output_cost = (output_tokens / 1000.0) * pricing[:output]
    
    {
      input_cost: input_cost.round(6),
      output_cost: output_cost.round(6),
      total_cost: (input_cost + output_cost).round(6)
    }
  end

  def self.total_token_limit_for_model(model = nil)
    ApplicationConfig.token_limit(model)
  end

  private

  # Fallback token counting using character approximation
  def self.fallback_token_count(content)
    # Rough approximation: 1 token ≈ 4 characters for English text
    (content.length / 4.0).ceil
  end

  def self.fallback_chat_token_count(messages)
    total = 0
    messages.each do |message|
      # Count role and content tokens (message format)
      total += fallback_token_count(message[:role].to_s)
      total += fallback_token_count(message[:content].to_s)
      total += 4  # overhead per message
    end
    total + 3  # assistant priming
  end

  def self.message_overhead_for_model(model)
    case model
    when 'gpt-3.5-turbo', 'gpt-3.5-turbo-1106'
      4
    when 'gpt-4', 'gpt-4-1106-preview', 'gpt-4o'
      3
    else
      4
    end
  end

  def self.model_pricing(model)
    ApplicationConfig.pricing(model)
  end
end
