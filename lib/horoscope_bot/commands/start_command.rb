# frozen_string_literal: true

module HoroscopeBot
  module Commands
    class StartCommand < BaseCommand
      WELCOME = <<~TEXT
        🔮 Добро пожаловать в Гороскоп-бот!

        Я умею:
        • присылать ежедневный гороскоп по вашему знаку
        • рассчитывать совместимость двух знаков
        • делать расклады Таро (1, 3 или 5 карт)
        • хранить историю ваших раскладов

        Пользуйтесь кнопками ниже 👇
        Для начала нажмите «⚙️ Настройки» и укажите дату рождения.
      TEXT

      def call
        states.reset(user_id)
        users.save(user_id, first_seen_at: Time.now.iso8601)
        reply_with_keyboard(WELCOME, Keyboards::MAIN_MENU)
      end
    end
  end
end
