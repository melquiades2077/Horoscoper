# frozen_string_literal: true

module HoroscopeBot
  module Commands
    # Базовый класс для всех команд бота.
    #
    # Чтобы добавить новую команду:
    #   1. Унаследоваться от BaseCommand
    #   2. Переопределить #call и/или #handle_state (и/или #handle_callback)
    #   3. Зарегистрировать в CommandRouter
    class BaseCommand
      attr_reader :message, :bot, :ctx

      def initialize(message:, bot:, ctx:)
        @message = message
        @bot = bot
        @ctx = ctx
      end

      # Вызывается при получении команды (например, /horoscope).
      def call
        raise NotImplementedError, "#{self.class} должен реализовать #call"
      end

      # Вызывается, если пользователь отправил текст в активном состоянии.
      def handle_state(_state)
        nil
      end

      # Вызывается при нажатии inline-кнопки.
      # @param _state [States::UserState]
      # @param _callback_data [String] значение callback_data нажатой кнопки
      def handle_callback(_state, _callback_data)
        nil
      end

      protected

      def user_id
        message.from.id.to_s
      end

      def chat_id
        message.chat.id
      end

      def reply(text, **opts)
        bot.api.send_message(chat_id:, text:, **opts)
      end

      # Reply-клавиатура (постоянное меню снизу экрана).
      # Разметку передаём как plain hash — Telegram API принимает JSON,
      # и гем сам сериализует хэш. Это надёжнее, чем зависеть от dry-struct
      # валидации в конкретной версии telegram-bot-ruby.
      # @param buttons [Array<Array<String>>] массив рядов кнопок
      def reply_with_keyboard(text, buttons)
        markup = {
          keyboard: buttons.map { |row| row.map { |label| { text: label } } },
          resize_keyboard: true,
          one_time_keyboard: false,
          is_persistent: true
        }
        reply(text, reply_markup: markup.to_json)
      end

      # Inline-клавиатура (кнопки под конкретным сообщением).
      # @param buttons [Array<Array<Hash>>] массив рядов,
      #   каждая кнопка — { text:, callback_data: }
      def reply_with_inline(text, buttons)
        markup = { inline_keyboard: buttons }
        reply(text, reply_markup: markup.to_json)
      end

      def users
        ctx[:users]
      end

      def states
        ctx[:states]
      end

      def logger
        ctx[:logger]
      end
    end
  end
end
