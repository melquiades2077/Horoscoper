# frozen_string_literal: true

module HoroscopeBot
  module Commands
    # Команда /tarot. Предлагает выбрать тип расклада через inline-кнопки,
    # делает расклад и сохраняет его в истории пользователя.
    #
    # callback_data имеет вид "tarot:<spread_key>", где spread_key —
    # один из ключей Services::TarotReader::SPREADS.
    class TarotCommand < BaseCommand
      CALLBACK_PREFIX = 'tarot'
      MAX_HISTORY_SIZE = 5

      INTRO = <<~TEXT
        🃏 Расклад карт Таро.

        Выберите тип расклада:
      TEXT

      def call
        states.set(user_id, States::UserState::AWAITING_TAROT_SPREAD)
        reply_with_inline(INTRO, spread_buttons)
      end

      def handle_callback(_state, callback_data)
        _prefix, spread_key = callback_data.split(':', 2)
        perform_spread(spread_key)
      end

      # Резервный сценарий: пользователь ввёл ключ расклада текстом.
      def handle_state(_state)
        key = message.text.to_s.strip.downcase
        if Services::TarotReader::SPREADS.key?(key)
          perform_spread(key)
        else
          reply('Пожалуйста, нажмите одну из кнопок выше или отправьте /cancel.')
        end
      end

      private

      def spread_buttons
        Services::TarotReader::SPREADS.map do |key, spread|
          [{ text: "#{spread[:title]} (#{spread[:count]})",
             callback_data: "#{CALLBACK_PREFIX}:#{key}" }]
        end
      end

      def perform_spread(spread_key)
        reader = Services::TarotReader.new
        cards = reader.draw(spread_key)
        text = Services::TarotReader.format(spread_key, cards)

        save_to_history(spread_key, cards)
        states.reset(user_id)
        reply(text)
      rescue ArgumentError => e
        logger&.error("TarotCommand: #{e.message}")
        reply('Не получилось сделать расклад. Попробуйте /tarot заново.')
      end

      # Сохраняет последние MAX_HISTORY_SIZE раскладов в профиле пользователя.
      def save_to_history(spread_key, cards)
        profile = users.find(user_id)
        history = Array(profile['tarot_history'])

        entry = {
          'date' => Time.now.iso8601,
          'spread' => spread_key,
          'cards' => cards.map { |c| c.transform_keys(&:to_s) }
        }

        updated = ([entry] + history).first(MAX_HISTORY_SIZE)
        users.save(user_id, tarot_history: updated)
        logger&.info("[Tarot] Saved spread=#{spread_key} for user=#{user_id}, total=#{updated.size}")
      rescue StandardError => e
        logger&.error("[Tarot] Failed to save history: #{e.class}: #{e.message}")
      end
    end
  end
end
