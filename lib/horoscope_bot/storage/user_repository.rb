# frozen_string_literal: true

module HoroscopeBot
  module Storage
    # Репозиторий пользователей.
    # Абстрагирует хранилище: в будущем можно заменить JsonStore на SQLite
    # без изменений в остальном коде.
    class UserRepository
      def initialize(store)
        @store = store
      end

      # @return [Hash] профиль пользователя или пустой хэш
      def find(user_id)
        @store.read(user_id) || {}
      end

      def save(user_id, attributes)
        current = find(user_id)
        updated = current.merge(stringify_keys(attributes))
        @store.write(user_id, updated)
      end

      def set_sign(user_id, sign_key)
        save(user_id, sign: sign_key)
      end

      def sign(user_id)
        find(user_id)['sign']
      end

      def exists?(user_id)
        @store.exists?(user_id)
      end

      def delete(user_id)
        @store.delete(user_id)
      end

      private

      def stringify_keys(hash)
        hash.transform_keys(&:to_s)
      end
    end
  end
end
