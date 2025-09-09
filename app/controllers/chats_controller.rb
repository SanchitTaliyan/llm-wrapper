class ChatsController < ApplicationController
  include ErrorHandler
  
  before_action :find_chat, only: [:show]

  def index
    chats = ChatService.list_chats
    
    respond_to do |format|
      format.html { @chats = chats }
      format.json { render json: ChatService.serialize_for_index(chats) }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: ChatService.serialize_for_show(@chat) }
    end
  end

  def create
    result = ChatService.create_chat(chat_params)
    
    if result[:success]
      render json: ChatService.serialize_for_create(result[:chat]), status: :created
    else
      render_validation_errors(result[:chat])
    end
  end

  private

  def find_chat
    @chat = ChatService.find_chat(params[:id])
  end

  def chat_params
    params.require(:chat).permit(:title)
  end
end
