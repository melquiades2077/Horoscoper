# frozen_string_literal: true

module HoroscopeBot
  module Commands
    # Настройка знака зодиака через дату рождения.
    # Использует состояние AWAITING_BIRTHDATE.
    class SettingsCommand < BaseCommand
      DATE_FORMATS = %w[%d.%m.%Y %d.%m %d/%m/%Y %d-%m-%Y].freeze

      def call
        states.set(user_id, States::UserState::AWAITING_BIRTHDATE)
        reply(<<~TEXT)
          📅 Пришлите дату вашего рождения в формате ДД.ММ.ГГГГ
          Например: 15.08.1995

          Или отправьте /cancel, чтобы отменить.
        TEXT
      end

      def handle_state(_state)
        text = message.text.to_s.strip
        date = parse_date(text)

        if date.nil?
          reply('Не получилось распознать дату. Формат: ДД.ММ.ГГГГ (например, 15.08.1995).')
          return
        end

        sign = Zodiac.by_date(date)
        if sign.nil?
          reply('Странно, но по этой дате я не смог определить знак. Попробуйте ещё раз.')
          return
        end

        users.save(user_id, sign: sign[:key], birthdate: date.iso8601)
        states.reset(user_id)
        reply("Готово! Ваш знак — #{Zodiac.format(sign)}. Теперь можете запросить /horoscope.")
      end

      private

      def parse_date(text)
        DATE_FORMATS.each do |fmt|
          return Date.strptime(text, fmt)
        rescue ArgumentError
          next
        end
        nil
      end
    end
  end
end
