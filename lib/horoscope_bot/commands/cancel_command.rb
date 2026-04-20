# frozen_string_literal: true

module HoroscopeBot
  module Commands
    class CancelCommand < BaseCommand
      def call
        state = states.get(user_id)
        if state.idle?
          reply('Нечего отменять — никаких активных диалогов.')
        else
          states.reset(user_id)
          reply('Отменено. Отправьте /help, чтобы увидеть список команд.')
        end
      end
    end
  end
end
