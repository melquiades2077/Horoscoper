# frozen_string_literal: true

module HoroscopeBot
  module Commands
    class RitualCommand < BaseCommand
      def call
        generator = Services::RitualGenerator.new
        reply(generator.generate(user_id))
      end
    end
  end
end
