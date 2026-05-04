# frozen_string_literal: true

module HoroscopeBot
  module Commands
    # Двухшаговая аффирмация:
    # 1) выбор сферы (love/career/energy)
    # 2) выбор тона (soft/strong)
    class AffirmationCommand < BaseCommand
      TOPIC_PREFIX = 'affirm_topic'
      TONE_PREFIX = 'affirm_tone'

      def call
        states.set(user_id, States::UserState::AWAITING_AFFIRMATION_TOPIC)
        reply_with_inline(
          "🕯️ Аффирмация дня.\n\nШаг 1/2: выберите сферу:",
          topic_buttons
        )
      end

      def handle_callback(state, callback_data)
        prefix, value = callback_data.split(':', 2)

        case prefix
        when TOPIC_PREFIX
          accept_topic(value)
        when TONE_PREFIX
          accept_tone(value, state)
        end
      end

      # Резервная текстовая ветка, если пользователь не нажимает кнопки.
      def handle_state(state)
        input = message.text.to_s.strip.downcase
        case state.name
        when States::UserState::AWAITING_AFFIRMATION_TOPIC
          topic = map_topic_text(input)
          return reply('Не понял сферу. Выберите: любовь, карьера или энергия.') if topic.nil?

          accept_topic(topic)
        when States::UserState::AWAITING_AFFIRMATION_TONE
          tone = map_tone_text(input)
          return reply('Не понял тон. Выберите: мягкий или сильный.') if tone.nil?

          accept_tone(tone, state)
        end
      end

      private

      def topic_buttons
        Services::AffirmationGenerator::TOPICS.map do |key, meta|
          [{ text: "#{meta[:emoji]} #{meta[:label]}", callback_data: "#{TOPIC_PREFIX}:#{key}" }]
        end
      end

      def tone_buttons
        Services::AffirmationGenerator::TONES.map do |key, meta|
          [{ text: "#{meta[:emoji]} #{meta[:label]}", callback_data: "#{TONE_PREFIX}:#{key}" }]
        end
      end

      def accept_topic(topic_key)
        topic = Services::AffirmationGenerator::TOPICS[topic_key]
        return reply('Неизвестная сфера, попробуйте снова.') if topic.nil?

        states.set(
          user_id,
          States::UserState::AWAITING_AFFIRMATION_TONE,
          { 'topic_key' => topic_key }
        )
        reply_with_inline(
          "Сфера: #{topic[:emoji]} #{topic[:label]}.\n\nШаг 2/2: выберите тон:",
          tone_buttons
        )
      end

      def accept_tone(tone_key, state)
        tone = Services::AffirmationGenerator::TONES[tone_key]
        return reply('Неизвестный тон, попробуйте снова.') if tone.nil?

        topic_key = state.context['topic_key']
        if topic_key.nil?
          states.reset(user_id)
          return reply('Не нашёл выбранную сферу. Давайте начнём заново: /affirmation')
        end

        text = Services::AffirmationGenerator.new.generate(
          user_id:,
          topic_key:,
          tone_key:
        )
        states.reset(user_id)
        reply(text)
      rescue ArgumentError => e
        logger&.error("AffirmationCommand: #{e.message}")
        reply('Не получилось собрать аффирмацию. Попробуйте /affirmation ещё раз.')
      end

      def map_topic_text(input)
        {
          'любовь' => 'love',
          'карьера' => 'career',
          'энергия' => 'energy'
        }[input]
      end

      def map_tone_text(input)
        {
          'мягкий' => 'soft',
          'сильный' => 'strong'
        }[input]
      end
    end
  end
end
