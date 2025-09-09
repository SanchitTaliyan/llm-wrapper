class ChatSerializer < BaseSerializer
  def serialize
    result = {
      id: object.id,
      title: object.title,
      created_at: formatted_timestamp(object.created_at),
      updated_at: formatted_timestamp(object.updated_at)
    }

    if options[:include_messages]
      result[:messages] = MessageSerializer.serialize_collection(ordered_messages)
    end

    if options[:include_last_message]
      last_msg = object.last_message
      result[:last_message] = last_msg ? MessageSerializer.new(last_msg).serialize : nil
    end

    result
  end

  def self.serialize_collection(chats, options = {})
    chats.map { |chat| new(chat, options).serialize }
  end

  private

  def ordered_messages
    object.messages.order(:created_at)
  end
end
