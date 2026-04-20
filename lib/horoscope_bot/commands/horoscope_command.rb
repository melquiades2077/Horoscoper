# frozen_string_literal: true

module HoroscopeBot
  module Commands
    class HoroscopeCommand < BaseCommand
      def call
        sign_key = users.sign(user_id)

        if sign_key.nil?
          reply('Сначала укажите ваш знак через /settings — мне нужна дата рождения.')
          return
        end

        generator = Services::HoroscopeGenerator.new
        reply(generator.generate(sign_key))
      rescue ArgumentError => e
        logger&.error("HoroscopeCommand: #{e.message}")
        reply('Что-то пошло не так при генерации гороскопа. Попробуйте /settings заново.')
      end
    end
  end
end
