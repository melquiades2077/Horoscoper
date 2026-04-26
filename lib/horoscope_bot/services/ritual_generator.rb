# frozen_string_literal: true

module HoroscopeBot
  module Services
    # Генерирует "ритуал дня":
    # короткое действие + фокус + благоприятное время.
    # Результат детерминирован для пары (user_id, date).
    class RitualGenerator
      ACTIONS = [
        'сделайте 3 глубоких вдоха у открытого окна',
        'запишите одну цель на день в заметки',
        'зажгите свечу и посидите в тишине 2 минуты',
        'выпейте стакан воды, мысленно отпуская тревоги',
        'сделайте короткую прогулку без телефона',
        'поблагодарите себя за один вчерашний шаг'
      ].freeze

      FOCI = [
        'ясность мыслей',
        'внутреннее спокойствие',
        'уверенность в решениях',
        'творческая энергия',
        'мягкая дисциплина',
        'гармония в общении'
      ].freeze

      TIMES = ['07:00-09:00', '10:00-12:00', '13:00-15:00', '17:00-19:00', '20:00-22:00'].freeze

      def initialize(date: Date.today, seed_salt: 'ritual')
        @date = date
        @seed_salt = seed_salt
      end

      def generate(user_id)
        rng = rng_for(user_id)
        action = ACTIONS.sample(random: rng)
        focus = FOCI.sample(random: rng)
        time = TIMES.sample(random: rng)

        <<~TEXT
          ✨ Ритуал дня на #{@date.strftime('%d.%m.%Y')}

          Действие: #{action}.
          Фокус: #{focus}.
          Лучшее время: #{time}.
        TEXT
      end

      private

      def rng_for(user_id)
        seed_string = "#{@seed_salt}-#{user_id}-#{@date.iso8601}"
        Random.new(seed_string.hash)
      end
    end
  end
end
