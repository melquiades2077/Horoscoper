# frozen_string_literal: true

module HoroscopeBot
  # Точка сборки приложения. Запускает polling и направляет обновления в роутер.
  class Application
    DEFAULT_USERS_PATH = File.join(ROOT, 'data', 'users.json').freeze
    DEFAULT_STATES_PATH = File.join(ROOT, 'data', 'states.json').freeze

    def initialize(token:, users_path: DEFAULT_USERS_PATH, states_path: DEFAULT_STATES_PATH, logger: default_logger)
      @token = token
      @users_path = users_path
      @states_path = states_path
      @logger = logger
    end

    def run
      @logger.info('Запуск Horoscope Bot...')
      Telegram::Bot::Client.run(@token) do |bot|
        router = CommandRouter.new(bot:, ctx: build_context)
        bot.listen { |update| dispatch(router, update) }
      end
    end

    # @api private — публичен для интеграционных тестов, где бот мокается.
    def build_context
      users_store = Storage::JsonStore.new(@users_path)
      states_store = Storage::JsonStore.new(@states_path)

      {
        users: Storage::UserRepository.new(users_store),
        states: States::StateMachine.new(states_store),
        logger: @logger
      }
    end

    private

    def dispatch(router, update)
      case update
      when Telegram::Bot::Types::Message        then router.route(update)
      when Telegram::Bot::Types::CallbackQuery  then router.route_callback(update)
      end
    end

    def default_logger
      logger = Logger.new($stdout)
      logger.level = Logger::INFO
      logger
    end
  end
end
