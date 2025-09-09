class MessagesController < ApplicationController
  include ErrorHandler
  
  before_action :find_chat

  def create
    result = MessageService.create_message_with_ai_response(@chat, message_params)
    
    if result[:success]
      render json: MessageService.serialize_message_response(
        result[:user_message], 
        result[:ai_message]
      ), status: :created
    else
      render_validation_errors(result[:user_message])
    end
  end

  private

  def find_chat
    @chat = ChatService.find_chat(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
