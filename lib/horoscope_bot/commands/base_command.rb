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
        bot.api.send_message(chat_id: chat_id, text: text, **opts)
      end

      # Reply-клавиатура (постоянное меню снизу экрана).
      # @param buttons [Array<Array<String>>] массив рядов кнопок
      def reply_with_keyboard(text, buttons)
        keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          keyboard: buttons,
          resize_keyboard: true,
          one_time_keyboard: false
        )
        reply(text, reply_markup: keyboard)
      end

      # Inline-клавиатура (кнопки под конкретным сообщением).
      # @param buttons [Array<Array<Hash>>] массив рядов,
      #   каждая кнопка — { text:, callback_data: }
      def reply_with_inline(text, buttons)
        rows = buttons.map do |row|
          row.map { |btn| Telegram::Bot::Types::InlineKeyboardButton.new(**btn) }
        end
        markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: rows)
        reply(text, reply_markup: markup)
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
