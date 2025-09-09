class MessageService
  class << self
    def create_message_with_ai_response(chat, message_params)
      user_message = chat.messages.build(message_params.merge(role: 'user'))
      
      return { success: false, user_message: user_message, errors: user_message.errors } unless user_message.save

      ai_response_result = generate_ai_response_for_chat(chat)
      ai_message = create_ai_message(chat, ai_response_result)

      # Update token usage if we have usage info
      if ai_response_result[:usage_info]
        update_message_tokens(user_message, ai_message, ai_response_result[:usage_info])
      end

      # Update chat title if this is the first exchange
      update_chat_title_if_needed(chat) if chat.messages.count == 2

      {
        success: true,
        user_message: user_message,
        ai_message: ai_message
      }
    end

    def serialize_message_response(user_message, ai_message)
      {
        user_message: MessageSerializer.new(user_message).serialize,
        ai_message: MessageSerializer.new(ai_message).serialize
      }
    end

    private

    def generate_ai_response_for_chat(chat)
      openai_service = OpenaiService.new
      
      token_info = openai_service.check_token_limits(chat)
      
      if !token_info[:within_limit] && token_info[:trimmed_messages_count] == 0
        Rails.logger.warn "Chat #{chat.id} exceeds token limits and cannot be trimmed further"
        return {
          content: "The conversation has become too long. Please start a new chat to continue.",
          usage_info: nil
        }
      end

      result = openai_service.generate_response(chat)
      
      if result.is_a?(Hash)
        {
          content: result[:content],
          usage_info: result[:usage]
        }
      else
        {
          content: result,
          usage_info: nil
        }
      end
      
    rescue StandardError => e
      Rails.logger.error "Failed to generate AI response for chat #{chat.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      error_content = if e.message.include?("context_length_exceeded")
        "The conversation has become too long. Please start a new chat to continue."
      else
        "I'm sorry, I'm having trouble processing your request right now. Please try again later."
      end

      {
        content: error_content,
        usage_info: nil
      }
    end

    def create_ai_message(chat, ai_response_result)
      chat.messages.create!(
        content: ai_response_result[:content],
        role: 'assistant'
      )
    end

    def update_message_tokens(user_message, assistant_message, usage_info)
      return unless usage_info

      current_model = ApplicationConfig.current_model
      
      user_input_tokens = TokenCountingService.count_message_tokens(
        user_message.content, 
        model: current_model
      )
      
      user_message.update_columns(
        input_tokens: user_input_tokens,
        output_tokens: 0,
        total_tokens: user_input_tokens
      )
      
      assistant_message.update_columns(
        input_tokens: 0,
        output_tokens: usage_info[:output_tokens],
        total_tokens: usage_info[:output_tokens]
      )
      
      user_message.chat.update_token_totals
      
      log_token_usage(user_message.chat, user_input_tokens, usage_info)
    end

    def log_token_usage(chat, user_input_tokens, usage_info)
      Rails.logger.info "Chat #{chat.id} token usage - User: #{user_input_tokens}, Assistant: #{usage_info[:output_tokens]}, API Input: #{usage_info[:input_tokens]}, API Output: #{usage_info[:output_tokens]}"
      
      openai_service = OpenaiService.new
      cost_info = openai_service.estimate_cost(chat)
      Rails.logger.info "Chat #{chat.id} estimated cost: $#{cost_info[:total_cost]} (input: $#{cost_info[:input_cost]}, output: $#{cost_info[:output_cost]})"
    end

    def update_chat_title_if_needed(chat)
      first_user_message = chat.messages.by_user.first
      return unless first_user_message

      title = first_user_message.content.truncate(50, omission: '...')
      chat.update(title: title)
    rescue StandardError => e
      Rails.logger.warn "Failed to update chat title for chat #{chat.id}: #{e.message}"
    end
  end
end
