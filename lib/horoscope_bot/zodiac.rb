# frozen_string_literal: true

module HoroscopeBot
  # Справочник знаков зодиака с датами, эмодзи и русскими названиями.
  module Zodiac
    SIGNS = [
      { key: 'aries',       name: 'Овен',        emoji: '♈', start: [3, 21],  stop: [4, 19] },
      { key: 'taurus',      name: 'Телец',       emoji: '♉', start: [4, 20],  stop: [5, 20] },
      { key: 'gemini',      name: 'Близнецы',    emoji: '♊', start: [5, 21],  stop: [6, 20] },
      { key: 'cancer',      name: 'Рак',         emoji: '♋', start: [6, 21],  stop: [7, 22] },
      { key: 'leo',         name: 'Лев',         emoji: '♌', start: [7, 23],  stop: [8, 22] },
      { key: 'virgo',       name: 'Дева',        emoji: '♍', start: [8, 23],  stop: [9, 22] },
      { key: 'libra',       name: 'Весы',        emoji: '♎', start: [9, 23],  stop: [10, 22] },
      { key: 'scorpio',     name: 'Скорпион',    emoji: '♏', start: [10, 23], stop: [11, 21] },
      { key: 'sagittarius', name: 'Стрелец',     emoji: '♐', start: [11, 22], stop: [12, 21] },
      { key: 'capricorn',   name: 'Козерог',     emoji: '♑', start: [12, 22], stop: [1, 19] },
      { key: 'aquarius',    name: 'Водолей',     emoji: '♒', start: [1, 20],  stop: [2, 18] },
      { key: 'pisces',      name: 'Рыбы',        emoji: '♓', start: [2, 19],  stop: [3, 20] }
    ].freeze

    module_function

    def all_keys
      SIGNS.map { |s| s[:key] }
    end

    def find(key)
      SIGNS.find { |s| s[:key] == key.to_s }
    end

    def find_by_name(name)
      normalized = name.to_s.strip.downcase
      SIGNS.find { |s| s[:name].downcase == normalized || s[:key] == normalized }
    end

    # Определяет знак зодиака по дате рождения.
    # @param date [Date]
    # @return [Hash, nil] запись знака или nil, если дата невалидна
    def by_date(date)
      return nil unless date.is_a?(Date)

      SIGNS.find { |sign| date_in_range?(date, sign) }
    end

    def format(sign)
      return '' if sign.nil?

      "#{sign[:emoji]} #{sign[:name]}"
    end

    def date_in_range?(date, sign)
      month = date.month
      day = date.day
      start_month, start_day = sign[:start]
      stop_month, stop_day = sign[:stop]

      if start_month <= stop_month
        after_or_equal_start?(month, day, start_month, start_day) &&
          before_or_equal_stop?(month, day, stop_month, stop_day)
      else
        # Козерог — переход через Новый год
        after_or_equal_start?(month, day, start_month, start_day) ||
          before_or_equal_stop?(month, day, stop_month, stop_day)
      end
    end

    def after_or_equal_start?(month, day, start_month, start_day)
      month > start_month || (month == start_month && day >= start_day)
    end

    def before_or_equal_stop?(month, day, stop_month, stop_day)
      month < stop_month || (month == stop_month && day <= stop_day)
    end
  end
end
