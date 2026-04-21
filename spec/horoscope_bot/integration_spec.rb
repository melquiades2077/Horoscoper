# frozen_string_literal: true

require 'tmpdir'

# Интеграционный тест: все слои работают вместе, Telegram API замокан через FakeBot.
RSpec.describe 'Bot integration', type: :integration do # rubocop:disable RSpec/DescribeClass
  let(:tmp_dir) { Dir.mktmpdir }
  let(:users_store) { HoroscopeBot::Storage::JsonStore.new(File.join(tmp_dir, 'users.json')) }
  let(:states_store) { HoroscopeBot::Storage::JsonStore.new(File.join(tmp_dir, 'states.json')) }
  let(:users) { HoroscopeBot::Storage::UserRepository.new(users_store) }
  let(:states) { HoroscopeBot::States::StateMachine.new(states_store) }
  let(:logger) { Logger.new(IO::NULL) }
  let(:ctx) { { users: users, states: states, logger: logger } }
  let(:bot) { FakeBot.new }
  let(:router) { HoroscopeBot::CommandRouter.new(bot: bot, ctx: ctx) }

  after { FileUtils.rm_rf(tmp_dir) }

  def send_message(text, user_id: 42)
    router.route(MessageBuilder.build(text: text, user_id: user_id))
  end

  def click_inline(data, user_id: 42)
    router.route_callback(MessageBuilder.build_callback(data: data, user_id: user_id))
  end

  describe '/start' do
    it 'приветствует и показывает главное меню-клавиатуру' do
      send_message('/start')
      expect(bot.api.last_text).to include('Добро пожаловать')
      expect(bot.api.last_markup).to include('keyboard')
      expect(bot.api.last_markup).to include('🔮 Гороскоп')
      expect(states.get('42')).to be_idle
    end
  end

  describe 'нажатие reply-кнопки' do
    it 'кнопка "🔮 Гороскоп" работает как /horoscope' do
      users.set_sign('42', 'leo')
      send_message('🔮 Гороскоп')
      expect(bot.api.last_text).to include('Лев')
    end

    it 'кнопка "❓ Помощь" работает как /help' do
      send_message('❓ Помощь')
      expect(bot.api.last_text).to include('Справка')
    end
  end

  describe 'полный сценарий настройки знака' do
    it 'запрашивает дату, принимает её, сохраняет знак' do
      send_message('/settings')
      expect(bot.api.last_text).to include('дату вашего рождения')
      expect(states.get('42').name).to eq('awaiting_birthdate')

      send_message('15.08.1995')
      expect(bot.api.last_text).to include('Лев')
      expect(users.sign('42')).to eq('leo')
      expect(states.get('42')).to be_idle
    end

    it 'на битой дате просит повторить, не теряя состояния' do
      send_message('/settings')
      send_message('не дата')
      expect(bot.api.last_text).to include('Не получилось распознать')
      expect(states.get('42').name).to eq('awaiting_birthdate')
    end
  end

  describe '/horoscope' do
    it 'требует /settings если знак не указан' do
      send_message('/horoscope')
      expect(bot.api.last_text).to include('Сначала укажите')
    end

    it 'выдаёт гороскоп после указания знака' do
      users.set_sign('42', 'leo')
      send_message('/horoscope')
      expect(bot.api.last_text).to include('Лев')
      expect(bot.api.last_text).to include('Число дня')
    end
  end

  describe 'совместимость через inline-кнопки' do
    it 'показывает inline-кнопки со знаками при /compatibility' do
      send_message('/compatibility')
      markup = bot.api.last_markup
      expect(markup).to include('inline_keyboard')
      expect(markup).to include('compat1:leo')
      expect(states.get('42').name).to eq('awaiting_compatibility_first')
    end

    it 'проводит пользователя через весь сценарий нажатиями кнопок' do
      send_message('/compatibility')

      click_inline('compat1:leo')
      expect(bot.api.last_text).to include('Первый знак: ♌ Лев')
      expect(states.get('42').name).to eq('awaiting_compatibility_second')
      expect(states.get('42').context['first_sign']).to eq('leo')

      click_inline('compat2:aries')
      expect(bot.api.last_text).to include('Совместимость')
      expect(bot.api.last_text).to match(/\d+%/)
      expect(states.get('42')).to be_idle
    end

    it 'отвечает на callback_query (убирает часик на кнопке)' do
      send_message('/compatibility')
      click_inline('compat1:leo')
      expect(bot.api.answered_callbacks).to include('cb1')
    end

    it 'всё ещё принимает ввод текстом как резервный вариант' do
      send_message('/compatibility')
      send_message('Лев')
      expect(bot.api.last_text).to include('Первый знак')
      send_message('Овен')
      expect(bot.api.last_text).to include('Совместимость')
    end
  end

  describe '/cancel' do
    it 'сбрасывает активный диалог' do
      send_message('/settings')
      send_message('/cancel')
      expect(bot.api.last_text).to include('Отменено')
      expect(states.get('42')).to be_idle
    end

    it 'говорит, что отменять нечего, если в idle' do
      send_message('/cancel')
      expect(bot.api.last_text).to include('Нечего отменять')
    end
  end

  describe 'неизвестные команды и просто текст' do
    it 'на неизвестную команду отправляет справку' do
      send_message('/unknowncommand')
      expect(bot.api.last_text).to include('Неизвестная команда')
    end

    it 'на обычный текст без состояния — fallback' do
      send_message('просто привет')
      expect(bot.api.last_text).to include('Не понимаю')
    end
  end

  describe 'изоляция пользователей' do
    it 'два разных user_id имеют независимые состояния и данные' do
      send_message('/settings', user_id: 1)
      send_message('/horoscope', user_id: 2)
      expect(bot.api.last_text).to include('Сначала укажите')

      expect(states.get('1').name).to eq('awaiting_birthdate')
      expect(states.get('2')).to be_idle
    end
  end

  describe 'персистентность при перезапуске бота' do
    it 'состояние и профиль сохраняются после пересоздания роутера' do
      send_message('/settings')
      send_message('15.08.1995')

      fresh_users_store = HoroscopeBot::Storage::JsonStore.new(File.join(tmp_dir, 'users.json'))
      fresh_users = HoroscopeBot::Storage::UserRepository.new(fresh_users_store)
      expect(fresh_users.sign('42')).to eq('leo')
    end
  end

  describe '/tarot через inline-кнопки' do
    it 'показывает кнопки выбора типа расклада' do
      send_message('/tarot')
      expect(bot.api.last_markup).to include('inline_keyboard')
      expect(bot.api.last_markup).to include('tarot:single')
      expect(states.get('42').name).to eq('awaiting_tarot_spread')
    end

    it 'делает расклад single и сбрасывает состояние' do
      send_message('/tarot')
      click_inline('tarot:single')
      expect(bot.api.last_text).to include('Карта дня')
      expect(states.get('42')).to be_idle
    end

    it 'делает расклад three с тремя позициями' do
      send_message('/tarot')
      click_inline('tarot:three')
      text = bot.api.last_text
      expect(text).to include('— Прошлое —')
      expect(text).to include('— Настоящее —')
      expect(text).to include('— Будущее —')
    end

    it 'сохраняет расклад в историю пользователя' do
      send_message('/tarot')
      click_inline('tarot:single')

      history = users.find('42')['tarot_history']
      expect(history).to be_an(Array)
      expect(history.size).to eq(1)
      expect(history.first['spread']).to eq('single')
    end

    it 'история ограничена 5 записями' do
      7.times do
        send_message('/tarot')
        click_inline('tarot:single')
      end

      history = users.find('42')['tarot_history']
      expect(history.size).to eq(5)
    end
  end

  describe '/history' do
    it 'сообщает, что истории нет, когда раскладов не было' do
      send_message('/history')
      expect(bot.api.last_text).to include('пока нет сохранённых')
    end

    it 'показывает последний расклад' do
      send_message('/tarot')
      click_inline('tarot:three')

      send_message('/history')
      expect(bot.api.last_text).to include('последние расклады')
      expect(bot.api.last_text).to include('Прошлое — Настоящее — Будущее')
    end
  end
end
