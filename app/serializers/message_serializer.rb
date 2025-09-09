class MessageSerializer < BaseSerializer
  def serialize
    {
      id: object.id,
      content: object.content,
      role: object.role,
      created_at: formatted_timestamp(object.created_at)
    }
  end
  
  def self.serialize_collection(messages)
    messages.map { |message| new(message).serialize }
  end
end
