class UsageService
  class << self
    def overall_usage_stats
      {
        total_chats: Chat.count,
        total_messages: Message.count,
        total_tokens: Chat.sum(:total_tokens) || 0,
        total_input_tokens: Chat.sum(:total_input_tokens) || 0,
        total_output_tokens: Chat.sum(:total_output_tokens) || 0,
        today: daily_usage_stats(Date.current),
        this_month: monthly_usage_stats(Date.current.beginning_of_month),
        models_used: model_usage_stats,
        cost_estimates: calculate_total_costs
      }
    end

    def chat_usage_stats(chat)
      openai_service = OpenaiService.new
      
      {
        chat_id: chat.id,
        title: chat.title,
        total_messages: chat.messages.count,
        total_tokens: chat.total_tokens || 0,
        total_input_tokens: chat.total_input_tokens || 0,
        total_output_tokens: chat.total_output_tokens || 0,
        model_used: chat.model_used || ApplicationConfig.current_model,
        token_limits: openai_service.check_token_limits(chat),
        cost_estimate: openai_service.estimate_cost(chat),
        daily_usage: chat.daily_token_usage,
        monthly_usage: chat.monthly_token_usage,
        created_at: chat.created_at,
        last_activity: chat.updated_at
      }
    end

    def daily_usage_stats(date)
      messages_today = Message.where(
        created_at: date.beginning_of_day..date.end_of_day
      )
      
      chats_today = Chat.joins(:messages).where(
        messages: { created_at: date.beginning_of_day..date.end_of_day }
      ).distinct
      
      {
        messages_count: messages_today.count,
        chats_count: chats_today.count,
        total_tokens: messages_today.sum(:total_tokens) || 0,
        input_tokens: messages_today.sum(:input_tokens) || 0,
        output_tokens: messages_today.sum(:output_tokens) || 0,
        cost_estimate: calculate_daily_cost(date)
      }
    end

    def monthly_usage_stats(month)
      messages_month = Message.where(
        created_at: month..month.end_of_month
      )
      
      chats_month = Chat.joins(:messages).where(
        messages: { created_at: month..month.end_of_month }
      ).distinct
      
      {
        messages_count: messages_month.count,
        chats_count: chats_month.count,
        total_tokens: messages_month.sum(:total_tokens) || 0,
        input_tokens: messages_month.sum(:input_tokens) || 0,
        output_tokens: messages_month.sum(:output_tokens) || 0,
        cost_estimate: calculate_monthly_cost(month)
      }
    end

    def top_chats_by_usage(limit = 10)
      chats = Chat.joins(:messages)
                  .where.not(total_tokens: nil)
                  .order(total_tokens: :desc)
                  .limit(limit)
                  .includes(:messages)
      
      chats.map do |chat|
        openai_service = OpenaiService.new
        {
          id: chat.id,
          title: chat.title || "Chat #{chat.id}",
          total_tokens: chat.total_tokens || 0,
          total_input_tokens: chat.total_input_tokens || 0,
          total_output_tokens: chat.total_output_tokens || 0,
          messages_count: chat.messages.count,
          model_used: chat.model_used || ApplicationConfig.current_model,
          cost_estimate: openai_service.estimate_cost(chat),
          created_at: chat.created_at,
          last_activity: chat.updated_at
        }
      end
    end

    def daily_stats_with_date(date)
      {
        date: date,
        **daily_usage_stats(date)
      }
    end

    def monthly_stats_with_date(month)
      {
        month: month,
        **monthly_usage_stats(month)
      }
    end

    def parse_date(date_string)
      return Date.current if date_string.blank?
      
      Date.parse(date_string)
    rescue ArgumentError
      raise ArgumentError, "Invalid date format: #{date_string}"
    end

    def parse_month(month_string)
      return Date.current.beginning_of_month if month_string.blank?
      
      Date.parse("#{month_string}-01")
    rescue ArgumentError
      raise ArgumentError, "Invalid month format: #{month_string}"
    end

    private

    def model_usage_stats
      Chat.where.not(model_used: nil)
          .group(:model_used)
          .count
    end

    def calculate_total_costs
      total_input = Chat.sum(:total_input_tokens) || 0
      total_output = Chat.sum(:total_output_tokens) || 0
      
      TokenCountingService.estimate_cost(total_input, total_output, model: ApplicationConfig.current_model)
    end

    def calculate_daily_cost(date)
      messages_today = Message.where(
        created_at: date.beginning_of_day..date.end_of_day
      )
      
      input_tokens = messages_today.sum(:input_tokens) || 0
      output_tokens = messages_today.sum(:output_tokens) || 0
      
      TokenCountingService.estimate_cost(input_tokens, output_tokens, model: ApplicationConfig.current_model)
    end

    def calculate_monthly_cost(month)
      messages_month = Message.where(
        created_at: month..month.end_of_month
      )
      
      input_tokens = messages_month.sum(:input_tokens) || 0
      output_tokens = messages_month.sum(:output_tokens) || 0
      
      TokenCountingService.estimate_cost(input_tokens, output_tokens, model: ApplicationConfig.current_model)
    end
  end
end
