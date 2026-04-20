# frozen_string_literal: true

module HoroscopeBot
  module Services
    # Вычисляет совместимость двух знаков зодиака.
    # Использует классическую астрологическую модель стихий:
    # Огонь (Овен, Лев, Стрелец), Земля (Телец, Дева, Козерог),
    # Воздух (Близнецы, Весы, Водолей), Вода (Рак, Скорпион, Рыбы).
    class CompatibilityCalculator
      ELEMENTS = {
        'aries' => :fire, 'leo' => :fire, 'sagittarius' => :fire,
        'taurus' => :earth, 'virgo' => :earth, 'capricorn' => :earth,
        'gemini' => :air, 'libra' => :air, 'aquarius' => :air,
        'cancer' => :water, 'scorpio' => :water, 'pisces' => :water
      }.freeze

      # Базовая совместимость стихий: одинаковые и дружественные пары высокие,
      # антагонистичные — низкие.
      ELEMENT_MATRIX = {
        %i[fire fire] => 85,  %i[fire air] => 90,   %i[fire earth] => 50, %i[fire water] => 45,
        %i[earth earth] => 85, %i[earth water] => 90, %i[earth air] => 50,  %i[earth fire] => 50,
        %i[air air] => 85,    %i[air fire] => 90,   %i[air water] => 55,  %i[air earth] => 50,
        %i[water water] => 85, %i[water earth] => 90, %i[water fire] => 45, %i[water air] => 55
      }.freeze

      def calculate(sign_a_key, sign_b_key)
        sign_a = Zodiac.find(sign_a_key)
        sign_b = Zodiac.find(sign_b_key)
        raise ArgumentError, 'Один из знаков не найден' if sign_a.nil? || sign_b.nil?

        score = compute_score(sign_a_key, sign_b_key)
        verdict = verdict_for(score)
        description = description_for(score, sign_a_key, sign_b_key)

        build_message(sign_a, sign_b, score, verdict, description)
      end

      private

      def compute_score(key_a, key_b)
        element_a = ELEMENTS.fetch(key_a)
        element_b = ELEMENTS.fetch(key_b)
        base = ELEMENT_MATRIX.fetch([element_a, element_b])
        # Небольшая детерминированная вариация, чтобы разные пары одной стихии
        # не давали одинаковое число
        modifier = ([key_a, key_b].sort.join.hash % 10) - 5
        (base + modifier).clamp(1, 99)
      end

      def verdict_for(score)
        case score
        when 80..99 then '💖 Идеальная пара'
        when 65..79 then '💞 Хорошая совместимость'
        when 50..64 then '💛 Нужно работать над отношениями'
        else             '💔 Сложный союз'
        end
      end

      def description_for(score, key_a, key_b)
        element_a = ELEMENTS.fetch(key_a)
        element_b = ELEMENTS.fetch(key_b)

        if element_a == element_b
          'Вы с партнёром говорите на одном языке — общая стихия даёт взаимопонимание.'
        elsif score >= 80
          'Ваши стихии дополняют друг друга, создавая гармоничный союз.'
        elsif score >= 50
          'В ваших отношениях есть и притяжение, и трения — но это нормально.'
        else
          'Стихии слишком разные. Придётся много трудиться для взаимопонимания.'
        end
      end

      def build_message(sign_a, sign_b, score, verdict, description)
        <<~MSG
          Совместимость #{Zodiac.format(sign_a)} и #{Zodiac.format(sign_b)}

          Результат: #{score}%
          #{verdict}

          #{description}
        MSG
      end
    end
  end
end
