# frozen_string_literal: true

module HoroscopeBot
  module Services
    # Колода Таро и логика раскладов.
    # Используются 22 Старших Аркана — этого достаточно для всех трёх раскладов
    # и делает код компактным.
    #
    # Каждая карта может выпасть в прямом или перевёрнутом положении —
    # перевёрнутая меняет смысл на противоположный или ослабленный.
    class TarotReader
      MAJOR_ARCANA = [
        { name: 'Шут',              upright: 'начало пути, спонтанность, свобода',
                                    reversed: 'наивность, безрассудство, страх перемен' },
        { name: 'Маг',              upright: 'сила воли, мастерство, воплощение замысла',
                                    reversed: 'манипуляции, нерешительность, скрытые мотивы' },
        { name: 'Верховная Жрица',  upright: 'интуиция, тайна, внутренний голос',
                                    reversed: 'поверхностность, самообман, игнорирование чутья' },
        { name: 'Императрица',      upright: 'плодородие, изобилие, забота',
                                    reversed: 'зависимость, пустота, творческий застой' },
        { name: 'Император',        upright: 'власть, структура, стабильность',
                                    reversed: 'тирания, упрямство, потеря контроля' },
        { name: 'Иерофант',         upright: 'традиция, наставничество, духовные ценности',
                                    reversed: 'догматизм, бунт против системы, непослушание' },
        { name: 'Влюблённые',       upright: 'любовь, выбор, союз',
                                    reversed: 'разлад, ошибка в выборе, дисбаланс' },
        { name: 'Колесница',        upright: 'победа, целеустремлённость, движение вперёд',
                                    reversed: 'поражение, потеря курса, внутренний конфликт' },
        { name: 'Сила',              upright: 'внутренняя сила, смелость, самоконтроль',
                                    reversed: 'слабость, сомнения, неуверенность' },
        { name: 'Отшельник',        upright: 'мудрость, поиск истины, уединение',
                                    reversed: 'одиночество, изоляция, потерянность' },
        { name: 'Колесо Фортуны',   upright: 'судьба, поворотный момент, удача',
                                    reversed: 'неудача, застой, дурные обстоятельства' },
        { name: 'Справедливость',   upright: 'правда, честность, равновесие',
                                    reversed: 'несправедливость, предвзятость, обман' },
        { name: 'Повешенный',       upright: 'жертва, пауза, новый взгляд',
                                    reversed: 'застой, бесполезные жертвы, сопротивление' },
        { name: 'Смерть',           upright: 'трансформация, окончание, перерождение',
                                    reversed: 'сопротивление переменам, страх нового' },
        { name: 'Умеренность',      upright: 'гармония, баланс, терпение',
                                    reversed: 'крайности, нетерпение, дисбаланс' },
        { name: 'Дьявол',           upright: 'соблазн, зависимость, материализм',
                                    reversed: 'освобождение, прозрение, разрыв оков' },
        { name: 'Башня',            upright: 'разрушение, внезапные перемены, откровение',
                                    reversed: 'избежание беды, страх перемен, затянувшийся кризис' },
        { name: 'Звезда',           upright: 'надежда, вдохновение, исцеление',
                                    reversed: 'разочарование, потеря веры, уныние' },
        { name: 'Луна',             upright: 'иллюзии, страхи, подсознание',
                                    reversed: 'рассеивание страхов, ясность, правда' },
        { name: 'Солнце',           upright: 'радость, успех, жизненная сила',
                                    reversed: 'грусть, временные неудачи, заблокированная энергия' },
        { name: 'Суд',              upright: 'возрождение, прощение, призвание',
                                    reversed: 'самокритика, сожаления, отказ от роста' },
        { name: 'Мир',              upright: 'завершение, целостность, успех',
                                    reversed: 'незавершённость, застой на финише' }
      ].freeze

      SPREADS = {
        'single'     => { count: 1, title: 'Карта дня',
                          positions: ['Сегодняшняя энергия'] },
        'three'      => { count: 3, title: 'Расклад «Прошлое — Настоящее — Будущее»',
                          positions: %w[Прошлое Настоящее Будущее] },
        'celtic'     => { count: 5, title: 'Упрощённый Кельтский крест',
                          positions: ['Текущая ситуация', 'Вызов', 'Прошлое',
                                      'Ближайшее будущее', 'Итог'] }
      }.freeze

      def initialize(rng: Random.new)
        @rng = rng
      end

      # Возвращает массив карт для расклада указанного типа.
      # @param spread_key [String] ключ из SPREADS (single/three/celtic)
      # @return [Array<Hash>] массив { name:, meaning:, reversed:, position: }
      def draw(spread_key)
        spread = SPREADS[spread_key]
        raise ArgumentError, "Неизвестный расклад: #{spread_key}" if spread.nil?

        cards = MAJOR_ARCANA.sample(spread[:count], random: @rng)
        cards.each_with_index.map do |card, i|
          reversed = @rng.rand(2).zero? # 50/50 на прямое/перевёрнутое
          {
            position: spread[:positions][i],
            name: card[:name],
            meaning: reversed ? card[:reversed] : card[:upright],
            reversed: reversed
          }
        end
      end

      # Форматирует расклад в читаемое сообщение.
      def self.format(spread_key, cards)
        spread = SPREADS[spread_key]
        lines = ["🃏 #{spread[:title]}", '']
        cards.each do |card|
          orientation = card[:reversed] ? ' (перевёрнутая)' : ''
          lines << "— #{card[:position]} —"
          lines << "#{card[:name]}#{orientation}"
          lines << card[:meaning]
          lines << ''
        end
        lines.join("\n").rstrip
      end
    end
  end
end
