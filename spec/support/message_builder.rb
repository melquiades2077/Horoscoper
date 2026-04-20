# frozen_string_literal: true

# Вспомогательные билдеры для тестов.
# Используем простые Struct'ы — не зависим от внутренней структуры
# конкретной версии telegram-bot-ruby.
module MessageBuilder
  FakeUser = Struct.new(:id)
  FakeChat = Struct.new(:id)
  FakeMessage = Struct.new(:text, :from, :chat)
  FakeCallback = Struct.new(:id, :data, :from, :message)

  module_function

  def build(text:, user_id: 42, chat_id: 42)
    FakeMessage.new(text, FakeUser.new(user_id), FakeChat.new(chat_id))
  end

  def build_callback(data:, user_id: 42, chat_id: 42, callback_id: 'cb1')
    msg = FakeMessage.new(nil, FakeUser.new(user_id), FakeChat.new(chat_id))
    FakeCallback.new(callback_id, data, FakeUser.new(user_id), msg)
  end
end

RSpec.configure do |config|
  config.include MessageBuilder
end
