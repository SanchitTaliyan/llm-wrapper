class Chat < ApplicationRecord
  has_many :messages, dependent: :destroy
  
  validates :title, length: { maximum: 255 }
  
  scope :recent, -> { order(updated_at: :desc) }
  
  def last_message
    messages.order(:created_at).last
  end
  
  def update_token_totals
    input_total = messages.sum(:input_tokens) || 0
    output_total = messages.sum(:output_tokens) || 0
    
    self.update_columns(
      total_input_tokens: input_total,
      total_output_tokens: output_total,
      total_tokens: input_total + output_total
    )
  end
  
  def total_available_tokens_for_history(model = nil)
    model ||= ApplicationConfig.current_model
    ApplicationConfig.available_tokens_for_history(model)
  end
  
  def messages_within_token_limit(model = nil)
    limit = total_available_tokens_for_history(model)
    selected_messages = []
    current_tokens = 0
    
    ordered_messages = messages.ordered.reverse
    
    ordered_messages.each do |message|
      message_tokens = message.total_tokens || message.calculate_token_count(model: model)
      if current_tokens + message_tokens <= limit
        selected_messages.unshift(message)
        current_tokens += message_tokens
      else
        break
      end
    end
    
    if selected_messages.empty? && ordered_messages.any?
      last_user_message = ordered_messages.find { |m| m.role == 'user' }
      if last_user_message
        selected_messages = [last_user_message]
        message_tokens = last_user_message.total_tokens || last_user_message.calculate_token_count(model: model)
        current_tokens += message_tokens
      end
    end
    
    return [current_tokens, selected_messages]
  end
  
  def calculate_history_tokens(model = nil)
    history_tokens, _ = messages_within_token_limit(model)
    return history_tokens
  end
  
  def exceeds_token_limit?(model = nil)
    model ||= ApplicationConfig.current_model
    calculate_history_tokens(model) > total_available_tokens_for_history(model)
  end
  
  def daily_token_usage(date = Date.current)
    messages.where(
      created_at: date.beginning_of_day..date.end_of_day
    ).sum(:total_tokens) || 0
  end
  
  def monthly_token_usage(month = Date.current.beginning_of_month)
    messages.where(
      created_at: month..month.end_of_month
    ).sum(:total_tokens) || 0
  end
end
