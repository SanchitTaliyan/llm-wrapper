class UsageController < ApplicationController
  include ErrorHandler
  
  before_action :find_chat, only: [:chat_usage]

  def index
    usage_stats = UsageService.overall_usage_stats
    
    respond_to do |format|
      format.html { @usage_stats = usage_stats }
      format.json { render json: UsageSerializer.serialize_overall_stats(usage_stats) }
    end
  end

  def chat_usage
    chat_usage = UsageService.chat_usage_stats(@chat)
    
    respond_to do |format|
      format.html { @chat_usage = chat_usage }
      format.json { render json: UsageSerializer.serialize_chat_usage(chat_usage) }
    end
  end

  def daily
    date = UsageService.parse_date(params[:date])
    daily_stats = UsageService.daily_stats_with_date(date)
    
    respond_to do |format|
      format.html { @daily_stats = daily_stats }
      format.json { render json: UsageSerializer.serialize_daily_stats(daily_stats) }
    end
  rescue ArgumentError => e
    render_error(e.message, :bad_request)
  end

  def monthly
    month = UsageService.parse_month(params[:month])
    monthly_stats = UsageService.monthly_stats_with_date(month)
    
    respond_to do |format|
      format.html { @monthly_stats = monthly_stats }
      format.json { render json: UsageSerializer.serialize_monthly_stats(monthly_stats) }
    end
  rescue ArgumentError => e
    render_error(e.message, :bad_request)
  end

  def top_chats
    limit = params[:limit]&.to_i || 10
    top_chats = UsageService.top_chats_by_usage(limit)
    
    respond_to do |format|
      format.html { @top_chats = top_chats }
      format.json { render json: UsageSerializer.serialize_top_chats(top_chats) }
    end
  end

  private

  def find_chat
    @chat = ChatService.find_chat(params[:chat_id] || params[:id])
  end
end
