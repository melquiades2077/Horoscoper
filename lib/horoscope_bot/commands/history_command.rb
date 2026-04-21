# frozen_string_literal: true

module HoroscopeBot
  module Commands
    # Показывает последние 5 раскладов Таро пользователя.
    class HistoryCommand < BaseCommand
      EMPTY = 'У вас пока нет сохранённых раскладов. Сделайте /tarot, чтобы начать.'

      def call
        profile = users.find(user_id)
        history = Array(profile['tarot_history'])
        logger&.info("[History] user=#{user_id} profile_keys=#{profile.keys.inspect} history_size=#{history.size}")

        return reply(EMPTY) if history.empty?

        reply(format_history(history))
      end

      private

      def format_history(history)
        lines = ['📜 Ваши последние расклады:', '']
        history.each_with_index do |entry, i|
          date = format_date(entry['date'])
          spread = Services::TarotReader::SPREADS.dig(entry['spread'], :title) || entry['spread']
          cards = Array(entry['cards']).map { |c| card_label(c) }.join(', ')
          lines << "#{i + 1}. #{date} — #{spread}"
          lines << "   #{cards}"
          lines << ''
        end
        lines.join("\n").rstrip
      end

      def format_date(iso_string)
        Time.parse(iso_string).strftime('%d.%m.%Y %H:%M')
      rescue ArgumentError, TypeError
        iso_string.to_s
      end

      def card_label(card)
        suffix = card['reversed'] ? ' ↓' : ''
        "#{card['name']}#{suffix}"
      end
    end
  end
end
