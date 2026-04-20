# frozen_string_literal: true

# Фейковый Telegram-бот для интеграционных тестов.
# Запоминает все отправленные сообщения и ответы на callback-и.
class FakeBotApi
  attr_reader :sent_messages, :answered_callbacks

  def initialize
    @sent_messages = []
    @answered_callbacks = []
  end

  def send_message(chat_id:, text:, **opts)
    @sent_messages << { chat_id: chat_id, text: text, **opts }
  end

  def answer_callback_query(callback_query_id:, **_opts)
    @answered_callbacks << callback_query_id
  end

  def last_text
    @sent_messages.last&.dig(:text)
  end

  def last_markup
    @sent_messages.last&.dig(:reply_markup)
  end
end

class FakeBot
  attr_reader :api

  def initialize
    @api = FakeBotApi.new
  end
end
