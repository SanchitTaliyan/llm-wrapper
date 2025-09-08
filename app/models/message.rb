class Message < ApplicationRecord
  belongs_to :chat
  
  validates :content, presence: true
  validates :role, presence: true, inclusion: { in: %w[user assistant] }
  
  scope :by_user, -> { where(role: 'user') }
  scope :by_assistant, -> { where(role: 'assistant') }
  scope :ordered, -> { order(:created_at) }
  
  # Token counting and management
  after_create :calculate_tokens, if: :should_calculate_tokens?
  
  def calculate_token_count(model: 'gpt-3.5-turbo')
    TokenCountingService.count_message_tokens(content, model: model)
  end
  
  def update_token_usage(model: 'gpt-3.5-turbo')
    token_count = calculate_token_count(model: model)
    
    if role == 'user'
      self.update_columns(
        input_tokens: token_count,
        output_tokens: 0,
        total_tokens: token_count
      )
    else # assistant
      self.update_columns(
        input_tokens: 0,
        output_tokens: token_count,
        total_tokens: token_count
      )
    end
    
    # Update chat totals
    chat.update_token_totals
  end
  
  private
  
  def should_calculate_tokens?
    content.present?
  end
  
  def calculate_tokens
    update_token_usage
  end
end
