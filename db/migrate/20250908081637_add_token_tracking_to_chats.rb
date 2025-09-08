class AddTokenTrackingToChats < ActiveRecord::Migration[8.0]
  def change
    add_column :chats, :total_input_tokens, :integer
    add_column :chats, :total_output_tokens, :integer
    add_column :chats, :total_tokens, :integer
    add_column :chats, :model_used, :string
  end
end
