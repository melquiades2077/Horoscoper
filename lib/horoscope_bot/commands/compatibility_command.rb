# frozen_string_literal: true

module HoroscopeBot
  module Commands
    # Двухшаговый выбор знаков через inline-кнопки.
    # callback_data: "compat1:<sign_key>" на первом шаге, "compat2:<sign_key>" на втором.
    class CompatibilityCommand < BaseCommand
      CALLBACK_PREFIX_FIRST = 'compat1'
      CALLBACK_PREFIX_SECOND = 'compat2'

      def call
        states.set(user_id, States::UserState::AWAITING_COMPATIBILITY_FIRST)
        reply_with_inline(
          '💞 Расчёт совместимости.

Выберите первый знак зодиака:',
          Keyboards.zodiac_inline(CALLBACK_PREFIX_FIRST)
        )
      end

      # Резервная обработка — если пользователь всё же вводит текст вместо нажатия кнопки,
      # пробуем распознать его как название знака.
      def handle_state(state)
        sign = Zodiac.find_by_name(message.text)
        if sign.nil?
          reply('Пожалуйста, нажмите одну из кнопок выше или отправьте /cancel.')
          return
        end

        case state.name
        when States::UserState::AWAITING_COMPATIBILITY_FIRST  then accept_first(sign)
        when States::UserState::AWAITING_COMPATIBILITY_SECOND then accept_second(sign, state)
        end
      end

      def handle_callback(state, callback_data)
        prefix, sign_key = callback_data.split(':', 2)
        sign = Zodiac.find(sign_key)
        return reply('Неизвестный знак, попробуйте ещё раз.') if sign.nil?

        case prefix
        when CALLBACK_PREFIX_FIRST  then accept_first(sign)
        when CALLBACK_PREFIX_SECOND then accept_second(sign, state)
        end
      end

      private

      def accept_first(sign)
        states.set(
          user_id,
          States::UserState::AWAITING_COMPATIBILITY_SECOND,
          { 'first_sign' => sign[:key] }
        )
        reply_with_inline(
          "Первый знак: #{Zodiac.format(sign)}.

Теперь выберите второй:",
          Keyboards.zodiac_inline(CALLBACK_PREFIX_SECOND)
        )
      end

      def accept_second(sign_b, state)
        sign_a_key = state.context['first_sign']
        calculator = Services::CompatibilityCalculator.new
        result = calculator.calculate(sign_a_key, sign_b[:key])

        states.reset(user_id)
        reply(result)
      end
    end
  end
end
