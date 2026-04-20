# frozen_string_literal: true

module HoroscopeBot
  # Маршрутизатор входящих обновлений от Telegram.
  #
  # Умеет обрабатывать:
  #   • текстовые сообщения (команды вида /start и текст в активном состоянии)
  #   • нажатия reply-кнопок (текст кнопки маппится в команду)
  #   • inline callback_query (нажатия кнопок под сообщением)
  #
  # Чтобы добавить новую команду — допиши её в COMMANDS / STATE_HANDLERS /
  # CALLBACK_HANDLERS ниже.
  class CommandRouter
    COMMANDS = {
      '/start' => Commands::StartCommand,
      '/help' => Commands::HelpCommand,
      '/settings' => Commands::SettingsCommand,
      '/horoscope' => Commands::HoroscopeCommand,
      '/compatibility' => Commands::CompatibilityCommand,
      '/tarot' => Commands::TarotCommand,
      '/cancel' => Commands::CancelCommand
    }.freeze

    # Какая команда отвечает за обработку каждого состояния (текстом).
    STATE_HANDLERS = {
      States::UserState::AWAITING_BIRTHDATE => Commands::SettingsCommand,
      States::UserState::AWAITING_COMPATIBILITY_FIRST => Commands::CompatibilityCommand,
      States::UserState::AWAITING_COMPATIBILITY_SECOND => Commands::CompatibilityCommand
    }.freeze

    # Какая команда обрабатывает callback с данным префиксом (до первого двоеточия).
    # Например, callback_data="compat1:leo" → префикс "compat1" → CompatibilityCommand.
    CALLBACK_HANDLERS = {
      'compat1' => Commands::CompatibilityCommand,
      'compat2' => Commands::CompatibilityCommand
    }.freeze

    FALLBACK_TEXT = 'Не понимаю. Нажмите кнопку или отправьте /help.'

    def initialize(bot:, ctx:)
      @bot = bot
      @ctx = ctx
    end

    # Обработка обычного сообщения (текст/нажатие reply-кнопки).
    def route(message)
      return if message.text.nil?

      user_id = message.from.id.to_s
      text = normalize_text(message.text.strip)

      if command?(text)
        handle_command(message, text)
      else
        handle_state(message, user_id)
      end
    rescue StandardError => e
      @ctx[:logger]&.error("Router error: #{e.class}: #{e.message}")
      send_fallback(message.chat.id, 'Произошла ошибка. Попробуйте /cancel и начните заново.')
    end

    # Обработка нажатия inline-кнопки (callback_query).
    def route_callback(callback_query)
      user_id = callback_query.from.id.to_s
      data = callback_query.data.to_s
      prefix = data.split(':', 2).first
      handler_class = CALLBACK_HANDLERS[prefix]

      # Подтверждаем получение callback — без этого у пользователя крутится часик на кнопке.
      answer_callback(callback_query.id)

      return if handler_class.nil?

      message = callback_query.message
      state = @ctx[:states].get(user_id)
      handler_class.new(message: message, bot: @bot, ctx: @ctx).handle_callback(state, data)
    rescue StandardError => e
      @ctx[:logger]&.error("Callback router error: #{e.class}: #{e.message}")
    end

    private

    # Превращает нажатие reply-кнопки ("🔮 Гороскоп") в команду ("/horoscope").
    def normalize_text(text)
      Keyboards::BUTTON_TO_COMMAND.fetch(text, text)
    end

    def command?(text)
      text.start_with?('/')
    end

    def handle_command(message, text)
      cmd_key = text.split.first
      command_class = COMMANDS[cmd_key]

      if command_class
        command_class.new(message: message, bot: @bot, ctx: @ctx).call
      else
        send_fallback(message.chat.id, "Неизвестная команда: #{cmd_key}. Отправьте /help.")
      end
    end

    def handle_state(message, user_id)
      state = @ctx[:states].get(user_id)

      if state.idle?
        send_fallback(message.chat.id, FALLBACK_TEXT)
        return
      end

      handler_class = STATE_HANDLERS[state.name]
      if handler_class.nil?
        @ctx[:states].reset(user_id)
        send_fallback(message.chat.id, 'Состояние сброшено. Отправьте /help.')
        return
      end

      handler_class.new(message: message, bot: @bot, ctx: @ctx).handle_state(state)
    end

    def send_fallback(chat_id, text)
      @bot.api.send_message(chat_id: chat_id, text: text)
    end

    def answer_callback(callback_query_id)
      @bot.api.answer_callback_query(callback_query_id: callback_query_id)
    rescue StandardError
      # не критично, если не получилось — продолжаем
    end
  end
end
