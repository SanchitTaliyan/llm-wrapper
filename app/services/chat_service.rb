class ChatService
  class << self
    def create_chat(params)
      chat = Chat.new(params)
      
      if chat.save
        { success: true, chat: chat }
      else
        { success: false, chat: chat, errors: chat.errors }
      end
    end

    def list_chats(options = {})
      chats = Chat.recent.includes(:messages)
      
      # Apply any filtering options here if needed in the future
      if options[:limit]
        chats = chats.limit(options[:limit])
      end

      chats
    end

    def find_chat(id)
      Chat.find(id)
    rescue ActiveRecord::RecordNotFound => e
      raise e
    end

    def serialize_for_index(chats)
      ChatSerializer.serialize_collection(chats, include_last_message: true)
    end

    def serialize_for_show(chat)
      ChatSerializer.new(chat, include_messages: true).serialize
    end

    def serialize_for_create(chat)
      ChatSerializer.new(chat).serialize
    end
  end
end
