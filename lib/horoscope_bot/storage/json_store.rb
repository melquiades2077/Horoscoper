# frozen_string_literal: true

module HoroscopeBot
  module Storage
    # Потокобезопасная обёртка над JSON-файлом.
    # Используется как key-value хранилище.
    #
    # @example
    #   store = JsonStore.new('data/users.json')
    #   store.write('123', { name: 'Alex' })
    #   store.read('123') # => { "name" => "Alex" }
    class JsonStore
      def initialize(path)
        @path = path
        @mutex = Mutex.new
        ensure_file_exists
      end

      def read(key)
        @mutex.synchronize { load_data[key.to_s] }
      end

      def write(key, value)
        @mutex.synchronize do
          data = load_data
          data[key.to_s] = value
          save_data(data)
        end
        value
      end

      def delete(key)
        @mutex.synchronize do
          data = load_data
          result = data.delete(key.to_s)
          save_data(data)
          result
        end
      end

      def all
        @mutex.synchronize { load_data }
      end

      def exists?(key)
        @mutex.synchronize { load_data.key?(key.to_s) }
      end

      private

      def ensure_file_exists
        FileUtils.mkdir_p(File.dirname(@path))
        File.write(@path, '{}') unless File.exist?(@path)
      end

      def load_data
        content = File.read(@path)
        content.empty? ? {} : JSON.parse(content)
      rescue JSON::ParserError
        {}
      end

      def save_data(data)
        File.write(@path, JSON.pretty_generate(data))
      end
    end
  end
end
