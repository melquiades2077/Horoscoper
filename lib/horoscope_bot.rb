# frozen_string_literal: true

require 'telegram/bot'
require 'json'
require 'date'
require 'fileutils'
require 'logger'

module HoroscopeBot
  ROOT = File.expand_path('..', __dir__)

  class Error < StandardError; end
end

require_relative 'horoscope_bot/version'
require_relative 'horoscope_bot/zodiac'
require_relative 'horoscope_bot/keyboards'
require_relative 'horoscope_bot/storage/json_store'
require_relative 'horoscope_bot/storage/user_repository'
require_relative 'horoscope_bot/states/user_state'
require_relative 'horoscope_bot/states/state_machine'
require_relative 'horoscope_bot/services/horoscope_generator'
require_relative 'horoscope_bot/services/compatibility_calculator'
require_relative 'horoscope_bot/services/tarot_reader'
require_relative 'horoscope_bot/services/ritual_generator'
require_relative 'horoscope_bot/commands/base_command'
require_relative 'horoscope_bot/commands/start_command'
require_relative 'horoscope_bot/commands/help_command'
require_relative 'horoscope_bot/commands/horoscope_command'
require_relative 'horoscope_bot/commands/compatibility_command'
require_relative 'horoscope_bot/commands/tarot_command'
require_relative 'horoscope_bot/commands/history_command'
require_relative 'horoscope_bot/commands/ritual_command'
require_relative 'horoscope_bot/commands/settings_command'
require_relative 'horoscope_bot/commands/cancel_command'
require_relative 'horoscope_bot/command_router'
require_relative 'horoscope_bot/application'
