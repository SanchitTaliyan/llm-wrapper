class MessagesController < ApplicationController
  before_action :find_chat

  def create
    @message = @chat.messages.build(message_params.merge(role: 'user'))
    
    if @message.save
      ai_response = generate_ai_response
      
      if ai_response
        if ai_response.is_a?(Hash)
          response_content = ai_response[:content]
          usage_info = ai_response[:usage]
        else
          response_content = ai_response
          usage_info = nil
        end
        
        ai_message = @chat.messages.create!(
          content: response_content,
          role: 'assistant'
        )
        
        # Update token usage for both messages if we have usage info
        if usage_info
          update_message_tokens(@message, ai_message, usage_info)
        end
        
        # Update chat title if it's the first message
        update_chat_title if @chat.messages.count == 2
        
        render json: {
          user_message: @message.as_json(only: [:id, :content, :role, :created_at]),
          ai_message: ai_message.as_json(only: [:id, :content, :role, :created_at])
        }, status: :created
      else
        # Create an error message to show the user
        error_message = @chat.messages.create!(
          content: "I'm sorry, I'm having trouble processing your request right now. Please try again later.",
          role: 'assistant'
        )
        
        render json: { 
          user_message: @message.as_json(only: [:id, :content, :role, :created_at]),
          ai_message: error_message.as_json(only: [:id, :content, :role, :created_at])
        }, status: :created
      end
    else
      render json: { errors: @message.errors }, status: :unprocessable_entity
    end
  end

  private

  def find_chat
    @chat = Chat.find(params[:chat_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Chat not found' }, status: :not_found
  end

  def message_params
    params.require(:message).permit(:content)
  end

  def generate_ai_response
    openai_service = OpenaiService.new
    
    token_info = openai_service.check_token_limits(@chat)
    
    if !token_info[:within_limit] && token_info[:trimmed_messages_count] == 0
      Rails.logger.warn "Chat #{@chat.id} exceeds token limits and cannot be trimmed further"
      return "The conversation has become too long. Please start a new chat to continue."
    end

    result = openai_service.generate_response(@chat)
    
    return result
    
  rescue StandardError => e
    Rails.logger.error "Failed to generate AI response for chat #{@chat.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    if e.message.include?("context_length_exceeded")
      "The conversation has become too long. Please start a new chat to continue."
    else
      nil
    end
  end
  
  private
  
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
    
    @chat.update_token_totals
    
    Rails.logger.info "Chat #{@chat.id} token usage - User: #{user_input_tokens}, Assistant: #{usage_info[:output_tokens]}, API Input: #{usage_info[:input_tokens]}, API Output: #{usage_info[:output_tokens]}"
    
    openai_service = OpenaiService.new
    cost_info = openai_service.estimate_cost(@chat)
    Rails.logger.info "Chat #{@chat.id} estimated cost: $#{cost_info[:total_cost]} (input: $#{cost_info[:input_cost]}, output: $#{cost_info[:output_cost]})"
  end

  def update_chat_title
    first_message_content = @chat.messages.by_user.first.content
    title = first_message_content.truncate(50, omission: '...')
    @chat.update(title: title)
  end
end
