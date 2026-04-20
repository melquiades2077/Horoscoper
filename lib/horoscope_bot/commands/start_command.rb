# frozen_string_literal: true

module HoroscopeBot
  module Commands
    class StartCommand < BaseCommand
      WELCOME = <<~TEXT
        🔮 Добро пожаловать в Гороскоп-бот!

        Я умею:
        • присылать ежедневный гороскоп
        • рассчитывать совместимость двух знаков
        • делать расклады Таро (скоро)

        Пользуйся кнопками ниже 👇
        Для начала нажми «⚙️ Настройки» и укажи дату рождения.
      TEXT

      def call
        states.reset(user_id)
        users.save(user_id, first_seen_at: Time.now.iso8601)
        reply_with_keyboard(WELCOME, Keyboards::MAIN_MENU)
      end
    end
  end
end
