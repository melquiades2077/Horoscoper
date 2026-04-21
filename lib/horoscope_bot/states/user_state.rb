# frozen_string_literal: true

module HoroscopeBot
  module States
    # Состояние пользователя в боте.
    # Состояния хранятся персистентно — после перезапуска бота ничего не теряется.
    class UserState
      IDLE = 'idle'
      AWAITING_BIRTHDATE = 'awaiting_birthdate'
      AWAITING_COMPATIBILITY_FIRST = 'awaiting_compatibility_first'
      AWAITING_COMPATIBILITY_SECOND = 'awaiting_compatibility_second'
      AWAITING_TAROT_SPREAD = 'awaiting_tarot_spread'

      VALID_STATES = [
        IDLE,
        AWAITING_BIRTHDATE,
        AWAITING_COMPATIBILITY_FIRST,
        AWAITING_COMPATIBILITY_SECOND,
        AWAITING_TAROT_SPREAD
      ].freeze

      attr_reader :name, :context

      def initialize(name: IDLE, context: {})
        self.name = name
        @context = context || {}
      end

      def name=(value)
        raise ArgumentError, "Неизвестное состояние: #{value}" unless VALID_STATES.include?(value)

        @name = value
      end

      def idle?
        @name == IDLE
      end

      def to_h
        { 'name' => @name, 'context' => @context }
      end

      def self.from_h(hash)
        return new if hash.nil? || hash.empty?

        new(name: hash['name'] || IDLE, context: hash['context'] || {})
      end
    end
  end
end
