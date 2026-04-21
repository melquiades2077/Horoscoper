# frozen_string_literal: true

RSpec.describe HoroscopeBot::Services::TarotReader do
  subject(:reader) { described_class.new(rng: Random.new(42)) }

  describe '#draw' do
    it 'возвращает 1 карту для расклада single' do
      expect(reader.draw('single').size).to eq(1)
    end

    it 'возвращает 3 карты для расклада three' do
      expect(reader.draw('three').size).to eq(3)
    end

    it 'возвращает 5 карт для расклада celtic' do
      expect(reader.draw('celtic').size).to eq(5)
    end

    it 'каждая карта содержит все обязательные поля' do
      card = reader.draw('single').first
      expect(card).to include(:name, :meaning, :reversed, :position)
    end

    it 'в раскладе three каждой карте сопоставлена позиция' do
      cards = reader.draw('three')
      expect(cards.map { |c| c[:position] }).to eq(%w[Прошлое Настоящее Будущее])
    end

    it 'все карты в раскладе уникальны (колода не повторяет карту)' do
      cards = reader.draw('celtic')
      names = cards.map { |c| c[:name] }
      expect(names.uniq).to eq(names)
    end

    it 'reversed — булево значение (true/false)' do
      card = reader.draw('single').first
      expect([true, false]).to include(card[:reversed])
    end

    it 'при фиксированном seed результат детерминирован' do
      a = described_class.new(rng: Random.new(100)).draw('three')
      b = described_class.new(rng: Random.new(100)).draw('three')
      expect(a).to eq(b)
    end

    it 'бросает ArgumentError для несуществующего расклада' do
      expect { reader.draw('unknown') }.to raise_error(ArgumentError)
    end
  end

  describe '.format' do
    let(:cards) do
      [
        { position: 'Прошлое',   name: 'Шут',    meaning: 'начало',      reversed: false },
        { position: 'Настоящее', name: 'Маг',    meaning: 'манипуляции', reversed: true },
        { position: 'Будущее',   name: 'Солнце', meaning: 'радость',     reversed: false }
      ]
    end

    it 'включает заголовок расклада' do
      expect(described_class.format('three', cards)).to include('Прошлое — Настоящее — Будущее')
    end

    it 'перечисляет все позиции' do
      text = described_class.format('three', cards)
      %w[Прошлое Настоящее Будущее].each { |pos| expect(text).to include("— #{pos} —") }
    end

    it 'включает имена всех карт' do
      text = described_class.format('three', cards)
      expect(text).to include('Шут').and include('Маг').and include('Солнце')
    end

    it 'помечает перевёрнутые карты, но не прямые' do
      text = described_class.format('three', cards)
      expect(text).to include('Маг (перевёрнутая)')
      expect(text).not_to include('Шут (перевёрнутая)')
    end
  end
end
