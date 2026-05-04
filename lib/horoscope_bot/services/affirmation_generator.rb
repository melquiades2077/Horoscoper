# frozen_string_literal: true

module HoroscopeBot
  module Services
    # Генерирует короткую аффирмацию по выбранной сфере и тону.
    # Результат детерминирован для пары (user_id, date, topic, tone).
    class AffirmationGenerator
      TOPICS = {
        'love' => { label: 'Любовь', emoji: '💗' },
        'career' => { label: 'Карьера', emoji: '💼' },
        'energy' => { label: 'Энергия', emoji: '⚡' }
      }.freeze

      TONES = {
        'soft' => { label: 'Мягкий', emoji: '🌿' },
        'strong' => { label: 'Сильный', emoji: '🔥' }
      }.freeze

      TEMPLATES = {
        'love' => {
          'soft' => [
            'Я выбираю бережность к себе и открытость к тёплому общению.',
            'Моё сердце спокойно, и я притягиваю искренние отношения.'
          ],
          'strong' => [
            'Я достойна/достоин зрелой любви и строю честные границы.',
            'Я смело выбираю отношения, в которых меня ценят и слышат.'
          ]
        },
        'career' => {
          'soft' => [
            'Я двигаюсь к целям уверенно и в своём ритме.',
            'Каждый мой небольшой шаг усиливает профессиональный рост.'
          ],
          'strong' => [
            'Я действую решительно и беру ответственность за свой успех.',
            'Моя дисциплина превращает идеи в реальные результаты.'
          ]
        },
        'energy' => {
          'soft' => [
            'Я бережно наполняю себя и поддерживаю внутренний баланс.',
            'Моё тело и разум работают в гармонии и спокойствии.'
          ],
          'strong' => [
            'Я полна/полон энергии и направляю её в важные дела.',
            'Я управляю своим фокусом и сохраняю высокий тонус весь день.'
          ]
        }
      }.freeze

      def initialize(date: Date.today, seed_salt: 'affirmation')
        @date = date
        @seed_salt = seed_salt
      end

      def generate(user_id:, topic_key:, tone_key:)
        topic = TOPICS[topic_key]
        tone = TONES[tone_key]
        raise ArgumentError, "Неизвестная сфера: #{topic_key}" if topic.nil?
        raise ArgumentError, "Неизвестный тон: #{tone_key}" if tone.nil?

        rng = rng_for(user_id, topic_key, tone_key)
        text = TEMPLATES.fetch(topic_key).fetch(tone_key).sample(random: rng)

        <<~TEXT
          #{topic[:emoji]} Аффирмация дня на #{@date.strftime('%d.%m.%Y')}
          Сфера: #{topic[:label]}
          Тон: #{tone[:emoji]} #{tone[:label]}

          #{text}
        TEXT
      end

      private

      def rng_for(user_id, topic_key, tone_key)
        seed_string = "#{@seed_salt}-#{user_id}-#{@date.iso8601}-#{topic_key}-#{tone_key}"
        Random.new(seed_string.hash)
      end
    end
  end
end
