class UsageController < ApplicationController
  before_action :find_chat, only: [:chat_usage]

  # Get overall usage statistics
  def index
    @usage_stats = {
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
    
    respond_to do |format|
      format.html 
      format.json { render json: @usage_stats }
    end
  end

  # Get usage for a specific chat
  def chat_usage
    openai_service = OpenaiService.new
    
    @chat_usage = {
      chat_id: @chat.id,
      title: @chat.title,
      total_messages: @chat.messages.count,
      total_tokens: @chat.total_tokens || 0,
      total_input_tokens: @chat.total_input_tokens || 0,
      total_output_tokens: @chat.total_output_tokens || 0,
      model_used: @chat.model_used || ApplicationConfig.current_model,
      token_limits: openai_service.check_token_limits(@chat),
      cost_estimate: openai_service.estimate_cost(@chat),
      daily_usage: @chat.daily_token_usage,
      monthly_usage: @chat.monthly_token_usage,
      created_at: @chat.created_at,
      last_activity: @chat.updated_at
    }
    
    respond_to do |format|
      format.html # Will render app/views/usage/chat_usage.html.erb
      format.json { render json: @chat_usage }
    end
  end

  # Get daily usage breakdown
  def daily
    date = params[:date] ? Date.parse(params[:date]) : Date.current
    
    @daily_stats = {
      date: date,
      **daily_usage_stats(date)
    }
    
    respond_to do |format|
      format.html # Will render app/views/usage/daily.html.erb
      format.json { render json: @daily_stats }
    end
  rescue ArgumentError
    render json: { error: 'Invalid date format' }, status: :bad_request
  end

  # Get monthly usage breakdown
  def monthly
    month = params[:month] ? Date.parse("#{params[:month]}-01") : Date.current.beginning_of_month
    
    @monthly_stats = {
      month: month,
      **monthly_usage_stats(month)
    }
    
    respond_to do |format|
      format.html # Will render app/views/usage/monthly.html.erb
      format.json { render json: @monthly_stats }
    end
  rescue ArgumentError
    render json: { error: 'Invalid month format' }, status: :bad_request
  end

  # Get top chats by usage
  def top_chats
    limit = params[:limit]&.to_i || 10
    
    @top_chats = Chat.joins(:messages)
                    .where.not(total_tokens: nil)
                    .order(total_tokens: :desc)
                    .limit(limit)
                    .includes(:messages)
                    .map do |chat|
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
    
    respond_to do |format|
      format.html # Will render app/views/usage/top_chats.html.erb
      format.json { render json: @top_chats }
    end
  end

  private

  def find_chat
    @chat = Chat.find(params[:chat_id] || params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Chat not found' }, status: :not_found
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

  def model_usage_stats
    Chat.where.not(model_used: nil)
        .group(:model_used)
        .count
  end

  def calculate_total_costs
    total_input = Chat.sum(:total_input_tokens) || 0
    total_output = Chat.sum(:total_output_tokens) || 0
    
    # Calculate cost using default model (simplified - mixed model usage not accounted for)
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
