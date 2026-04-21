# frozen_string_literal: true

module HoroscopeBot
  # Разметка клавиатур. Вынесено в отдельный модуль,
  # чтобы все кнопки бота были в одном месте.
  module Keyboards
    # Главное reply-меню (кнопки снизу экрана).
    MAIN_MENU = [
      ['🔮 Гороскоп', '💞 Совместимость'],
      ['🃏 Таро', '📜 История'],
      ['⚙️ Настройки', '❓ Помощь']
    ].freeze

    # Маппинг текста кнопки reply-меню на команду.
    # Роутер использует его, чтобы нажатия кнопок работали как команды.
    BUTTON_TO_COMMAND = {
      '🔮 Гороскоп'       => '/horoscope',
      '💞 Совместимость'  => '/compatibility',
      '🃏 Таро'           => '/tarot',
      '📜 История'        => '/history',
      '⚙️ Настройки'      => '/settings',
      '❓ Помощь'          => '/help'
    }.freeze

    module_function

    # Inline-клавиатура со всеми 12 знаками зодиака (3 знака в ряд).
    def zodiac_inline(prefix)
      Zodiac::SIGNS.each_slice(3).map do |row|
        row.map do |sign|
          { text: "#{sign[:emoji]} #{sign[:name]}", callback_data: "#{prefix}:#{sign[:key]}" }
        end
      end
    end
  end
end
