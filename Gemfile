# frozen_string_literal: true

source 'https://rubygems.org'

ruby '>= 3.1'

gem 'telegram-bot-ruby', '~> 2.4'

group :development, :test do
  gem 'rspec', '~> 3.13'
  # Жёстко точные версии: более новые ломаются на Windows + Ruby 3.4
  # из-за транзитивных зависимостей rubocop-capybara и rubocop-factory_bot.
  gem 'rubocop', '1.63.5', require: false
  gem 'rubocop-rspec', '2.27.1', require: false
  gem 'simplecov', '~> 0.22', require: false
end
