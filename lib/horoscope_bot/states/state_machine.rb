# frozen_string_literal: true

module HoroscopeBot
  module States
    # Машина состояний. Хранит состояние каждого пользователя отдельно,
    # персистентно (через переданное хранилище), предоставляет API get/set/reset.
    class StateMachine
      def initialize(store)
        @store = store
      end

      # @return [UserState]
      def get(user_id)
        raw = @store.read(user_id)
        UserState.from_h(raw)
      end

      def set(user_id, state_name, context = {})
        state = UserState.new(name: state_name, context:)
        @store.write(user_id, state.to_h)
        state
      end

      def update_context(user_id, additional_context)
        state = get(user_id)
        merged = state.context.merge(stringify_keys(additional_context))
        set(user_id, state.name, merged)
      end

      def reset(user_id)
        @store.write(user_id, UserState.new.to_h)
      end

      private

      def stringify_keys(hash)
        hash.transform_keys(&:to_s)
      end
    end
  end
end
