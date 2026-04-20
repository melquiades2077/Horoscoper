# frozen_string_literal: true

module HoroscopeBot
  module Commands
    class HelpCommand < BaseCommand
      HELP_TEXT = <<~TEXT
        📖 Справка по командам

        /start — перезапустить бота
        /settings — указать дату рождения (определит ваш знак)
        /horoscope — ежедневный гороскоп
        /compatibility — совместимость двух знаков
        /tarot — карты Таро
        /cancel — отменить текущее действие
        /help — эта справка

        💡 Пользуйтесь кнопками под полем ввода — это быстрее,
        чем печатать команды вручную.
      TEXT

      def call
        reply_with_keyboard(HELP_TEXT, Keyboards::MAIN_MENU)
      end
    end
  end
end
