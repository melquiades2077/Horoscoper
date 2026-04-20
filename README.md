# 🔮 Horoscope Bot

Telegram-бот на Ruby, выдающий гороскопы, расчёт совместимости знаков зодиака и (скоро) расклады Таро.

Учебный проект. Написан с упором на чистую архитектуру, тесты и масштабируемость — чтобы добавление новых команд требовало минимум правок существующего кода.

## 📋 Возможности

| Команда | Что делает |
|---|---|
| `/start` | Приветствие, сброс состояния |
| `/help` | Список всех команд |
| `/settings` | Указать дату рождения (определяется знак зодиака) |
| `/horoscope` | Ежедневный гороскоп для вашего знака |
| `/compatibility` | Рассчитать совместимость двух знаков |
| `/tarot` | Расклад Таро *(в разработке)* |
| `/cancel` | Отменить текущий многошаговый диалог |

## 🚀 Запуск

### Требования
- Ruby >= 3.0
- Bundler

### Установка
```bash
git clone <url>
cd horoscope_bot
bundle install
```

### Запуск
Получите токен у [@BotFather](https://t.me/BotFather) и запустите:
```bash
TELEGRAM_BOT_TOKEN=your_token_here bundle exec ruby bin/horoscope_bot
```

Или положите токен в `.env` (этот файл игнорируется git):
```bash
echo "TELEGRAM_BOT_TOKEN=your_token_here" > .env
export $(cat .env | xargs)
bundle exec ruby bin/horoscope_bot
```

## 🧪 Тесты и линтер

```bash
bundle exec rspec         # запустить все тесты
bundle exec rubocop       # проверить стиль кода
bundle exec rake          # то и другое сразу
```

Отчёт о покрытии кода создаётся в `coverage/index.html` после запуска тестов.

## 🏗 Архитектура

```
lib/horoscope_bot/
├── application.rb          # Точка сборки: собирает зависимости, запускает polling
├── command_router.rb       # Маршрутизатор: /команды и обработчики состояний
├── zodiac.rb               # Справочник 12 знаков зодиака
├── commands/               # Паттерн Command — по файлу на команду
│   ├── base_command.rb     # Базовый класс всех команд
│   ├── start_command.rb
│   ├── help_command.rb
│   ├── settings_command.rb
│   ├── horoscope_command.rb
│   ├── compatibility_command.rb
│   ├── tarot_command.rb    # ← заглушка, реализует одногруппник
│   └── cancel_command.rb
├── states/                 # Машина состояний (FSM) для многошаговых диалогов
│   ├── user_state.rb       # Value-object состояния пользователя
│   └── state_machine.rb    # Логика переходов + персистентность
├── services/               # Бизнес-логика
│   ├── horoscope_generator.rb        # Детерминированный по дате генератор
│   └── compatibility_calculator.rb   # Матрица стихий (огонь/земля/воздух/вода)
└── storage/                # Персистентный слой
    ├── json_store.rb       # Потокобезопасное key-value на JSON
    └── user_repository.rb  # Репозиторий пользователей
```

### Ключевые решения

- **Паттерн Command.** Каждая команда — отдельный класс, наследующий `BaseCommand`. Добавить новую команду = создать класс + одна строка в `CommandRouter::COMMANDS`.
- **Машина состояний вместо if/case-свалки.** Многошаговые диалоги (/settings, /compatibility) управляются через `StateMachine`. Переходы, контекст и текущее состояние персистентны.
- **Персистентность через JSON.** Состояния и профили пользователей сохраняются в `data/*.json`. При перезапуске бота ничего не теряется. Абстракция `JsonStore` спрятана за репозиторием — можно без боли заменить на SQLite.
- **Инъекция зависимостей.** Команды получают `ctx` с репозиториями — легко мокать в тестах, легко подменять в продакшене.
- **Потокобезопасность.** `JsonStore` защищён `Mutex` для корректной работы при нескольких одновременных обновлениях.

## 🎯 Что делать одногруппнику

Тебе нужно реализовать раздел **«Карты Таро»**. Вся инфраструктура готова: бот запускается, состояния работают, данные персистентны, тесты и CI уже настроены. Нужно только добавить одну фичу.

### Пошагово

1. **Открой `lib/horoscope_bot/commands/tarot_command.rb`** — там в верхнем комментарии подробная инструкция с идеями.

2. **Создай сервис** `lib/horoscope_bot/services/tarot_reader.rb`:
   - хранит колоду (22 Старших Аркана минимум, можно все 78)
   - метод `#draw(count)` возвращает `count` случайных карт
   - каждая карта: `{ name:, meaning:, reversed: bool }`

3. **Реализуй `TarotCommand#call`** — предложи пользователю выбрать тип расклада:
   - 1 карта — карта дня
   - 3 карты — прошлое/настоящее/будущее
   - 5 карт — кельтский крест

4. **Добавь новое состояние** в `lib/horoscope_bot/states/user_state.rb`:
   ```ruby
   AWAITING_TAROT_SPREAD = 'awaiting_tarot_spread'
   VALID_STATES = [..., AWAITING_TAROT_SPREAD].freeze
   ```

5. **Зарегистрируй обработчик состояния** в `lib/horoscope_bot/command_router.rb`:
   ```ruby
   STATE_HANDLERS = {
     ...,
     States::UserState::AWAITING_TAROT_SPREAD => Commands::TarotCommand
   }.freeze
   ```

6. **Реализуй `TarotCommand#handle_state`** — по выбору пользователя вызови `TarotReader#draw` и выдай красивый ответ.

7. **Напиши тесты:**
   - `spec/horoscope_bot/services/tarot_reader_spec.rb`
   - `spec/horoscope_bot/commands/tarot_command_spec.rb`
   - добавь интеграционный сценарий в `spec/horoscope_bot/integration_spec.rb`

   Шаблон можно подсмотреть в `compatibility_calculator_spec.rb` и `integration_spec.rb` — логика аналогичная.

### Бонус-идеи (на всякий случай, если захочешь больше баллов)

- Сохранять историю раскладов в `UserRepository`: `users.save(user_id, last_tarot: {...})`.
- Добавить команду `/history` — последние 5 раскладов.
- Кешировать "карту дня" детерминированно (как это сделано в `HoroscopeGenerator`) — чтобы пользователь, дёргающий `/tarot` весь день, получал одну и ту же карту.

### Что НЕ нужно трогать

- `JsonStore`, `UserRepository`, `StateMachine` — готовы и протестированы
- `CommandRouter` — только добавить свою команду в хэши, не переписывать
- `Application`, `BaseCommand` — точки расширения, менять не нужно
- `.github/workflows/ci.yml` — CI автоматически прогонит твои тесты

## 🔐 Безопасность

Токен бота **никогда** не коммитится. `.env` и `data/*.json` в `.gitignore`.

## 📄 Лицензия

MIT
