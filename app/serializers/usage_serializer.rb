class UsageSerializer < BaseSerializer
  def serialize
    case options[:type]
    when :overall
      serialize_overall_stats
    when :chat
      serialize_chat_usage
    when :daily
      serialize_daily_stats
    when :monthly
      serialize_monthly_stats
    when :top_chats
      serialize_top_chats
    else
      object
    end
  end

  def self.serialize_overall_stats(stats)
    new(stats, type: :overall).serialize
  end

  def self.serialize_chat_usage(chat_usage)
    new(chat_usage, type: :chat).serialize
  end

  def self.serialize_daily_stats(daily_stats)
    new(daily_stats, type: :daily).serialize
  end

  def self.serialize_monthly_stats(monthly_stats)
    new(monthly_stats, type: :monthly).serialize
  end

  def self.serialize_top_chats(top_chats)
    new(top_chats, type: :top_chats).serialize
  end

  private

  def serialize_overall_stats
    {
      total_chats: object[:total_chats],
      total_messages: object[:total_messages],
      total_tokens: object[:total_tokens],
      total_input_tokens: object[:total_input_tokens],
      total_output_tokens: object[:total_output_tokens],
      today: serialize_usage_period(object[:today]),
      this_month: serialize_usage_period(object[:this_month]),
      models_used: object[:models_used],
      cost_estimates: serialize_cost_estimate(object[:cost_estimates])
    }
  end

  def serialize_chat_usage
    {
      chat_id: object[:chat_id],
      title: object[:title],
      total_messages: object[:total_messages],
      total_tokens: object[:total_tokens],
      total_input_tokens: object[:total_input_tokens],
      total_output_tokens: object[:total_output_tokens],
      model_used: object[:model_used],
      token_limits: object[:token_limits],
      cost_estimate: serialize_cost_estimate(object[:cost_estimate]),
      daily_usage: object[:daily_usage],
      monthly_usage: object[:monthly_usage],
      created_at: formatted_timestamp(object[:created_at]),
      last_activity: formatted_timestamp(object[:last_activity])
    }
  end

  def serialize_daily_stats
    {
      date: object[:date]&.iso8601,
      **serialize_usage_period(object)
    }
  end

  def serialize_monthly_stats
    {
      month: object[:month]&.iso8601,
      **serialize_usage_period(object)
    }
  end

  def serialize_top_chats
    object.map do |chat_data|
      {
        id: chat_data[:id],
        title: chat_data[:title],
        total_tokens: chat_data[:total_tokens],
        total_input_tokens: chat_data[:total_input_tokens],
        total_output_tokens: chat_data[:total_output_tokens],
        messages_count: chat_data[:messages_count],
        model_used: chat_data[:model_used],
        cost_estimate: serialize_cost_estimate(chat_data[:cost_estimate]),
        created_at: formatted_timestamp(chat_data[:created_at]),
        last_activity: formatted_timestamp(chat_data[:last_activity])
      }
    end
  end

  def serialize_usage_period(period_data)
    return {} unless period_data.is_a?(Hash)

    {
      messages_count: period_data[:messages_count],
      chats_count: period_data[:chats_count],
      total_tokens: period_data[:total_tokens],
      input_tokens: period_data[:input_tokens],
      output_tokens: period_data[:output_tokens],
      cost_estimate: serialize_cost_estimate(period_data[:cost_estimate])
    }.compact
  end

  def serialize_cost_estimate(cost_data)
    return nil unless cost_data.is_a?(Hash)

    {
      input_cost: cost_data[:input_cost]&.round(6),
      output_cost: cost_data[:output_cost]&.round(6),
      total_cost: cost_data[:total_cost]&.round(6)
    }
  end
end
