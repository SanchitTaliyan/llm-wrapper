class ChatsController < ApplicationController
  before_action :find_chat, only: [:show]

  def index
    @chats = Chat.recent.includes(:messages)
    
    respond_to do |format|
      format.html
      format.json {
        render json: @chats.as_json(
          include: {
            messages: {
              only: [:id, :content, :role, :created_at]
            }
          },
          methods: [:last_message]
        )
      }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json {
        render json: @chat.as_json(
          include: {
            messages: {
              only: [:id, :content, :role, :created_at],
              order: :created_at
            }
          }
        )
      }
    end
  end

  def create
    @chat = Chat.new(chat_params)
    
    if @chat.save
      render json: @chat, status: :created
    else
      render json: { errors: @chat.errors }, status: :unprocessable_entity
    end
  end

  private

  def find_chat
    @chat = Chat.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Chat not found' }, status: :not_found
  end

  def chat_params
    params.require(:chat).permit(:title)
  end
end
