# Create sample chat data for development
if Rails.env.development?
  # Clear existing data
  Chat.destroy_all

  # Create sample chats
  chat1 = Chat.create!(title: "Introduction to Rails")
  chat1.messages.create!(content: "Hi! Can you help me understand Ruby on Rails?", role: "user")
  chat1.messages.create!(content: "Of course! Ruby on Rails is a web application framework written in Ruby. It follows the Model-View-Controller (MVC) pattern and emphasizes convention over configuration.", role: "assistant")
  
  chat2 = Chat.create!(title: "Database Design")
  chat2.messages.create!(content: "What are some best practices for database design?", role: "user")
  chat2.messages.create!(content: "Here are some key database design principles:\n\n1. Normalize your data to reduce redundancy\n2. Use appropriate data types\n3. Create proper indexes\n4. Establish clear relationships between tables", role: "assistant")
  
  puts "Created #{Chat.count} sample chats with #{Message.count} messages"
end
