# frozen_string_literal: true

module HoroscopeBot
  module Services
    # Генерирует ежедневный гороскоп по знаку зодиака.
    # Детерминирован: для пары (знак, дата) результат всегда одинаков
    # до конца дня. Это сделано специально, чтобы пользователь,
    # запрашивая гороскоп несколько раз в день, получал один и тот же ответ.
    class HoroscopeGenerator
      TEMPLATES = [
        'Сегодня ваш день пройдёт под знаком %<theme>s. Главное — %<advice>s.',
        'Звёзды советуют %<advice>s. %<theme>s будет сопровождать вас весь день.',
        'День обещает %<theme>s. Не упустите возможность — %<advice>s.',
        'Энергия дня: %<theme>s. Лучшее, что можно сделать — %<advice>s.',
        'Вселенная намекает: %<theme>s. Попробуйте %<advice>s.'
      ].freeze

      THEMES = [
        'новых возможностей', 'спокойствия и размышлений', 'активных действий',
        'романтики', 'творческого вдохновения', 'финансового везения',
        'дружеских встреч', 'саморазвития', 'неожиданных открытий', 'гармонии с собой'
      ].freeze

      ADVICES = [
        'довериться интуиции', 'не торопиться с решениями', 'начать новое дело',
        'позвонить близкому человеку', 'отдохнуть и выспаться', 'попробовать что-то необычное',
        'сохранять баланс', 'быть открытым для общения', 'проявить терпение',
        'записать свои мысли в дневник'
      ].freeze

      LUCK_EMOJIS = %w[🌟 ✨ 🔮 🌙 ☀️ 💫 🍀 💎].freeze

      def initialize(date: Date.today, seed_salt: 'horoscope')
        @date = date
        @seed_salt = seed_salt
      end

      # @param sign_key [String] ключ знака (e.g. "aries")
      # @return [String] текст гороскопа
      def generate(sign_key)
        sign = Zodiac.find(sign_key)
        raise ArgumentError, "Неизвестный знак: #{sign_key}" if sign.nil?

        rng = rng_for(sign_key)
        template = TEMPLATES.sample(random: rng)
        theme = THEMES.sample(random: rng)
        advice = ADVICES.sample(random: rng)
        emoji = LUCK_EMOJIS.sample(random: rng)
        lucky_number = rng.rand(1..99)

        build_message(sign, template, theme, advice, emoji, lucky_number)
      end

      private

      def rng_for(sign_key)
        seed_string = "#{@seed_salt}-#{sign_key}-#{@date.iso8601}"
        Random.new(seed_string.hash)
      end

      def build_message(sign, template, theme, advice, emoji, lucky_number)
        body = format(template, theme: theme, advice: advice)
        <<~MSG
          #{emoji} Гороскоп для #{Zodiac.format(sign)} на #{@date.strftime('%d.%m.%Y')}

          #{body}

          Число дня: #{lucky_number}
        MSG
      end
    end
  end
end
