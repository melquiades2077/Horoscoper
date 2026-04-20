# frozen_string_literal: true

RSpec.describe HoroscopeBot::Zodiac do
  describe '.by_date' do
    it 'возвращает Льва для 1 августа' do
      expect(described_class.by_date(Date.new(2000, 8, 1))[:key]).to eq('leo')
    end

    it 'возвращает Козерога для 31 декабря (переход через год)' do
      expect(described_class.by_date(Date.new(2000, 12, 31))[:key]).to eq('capricorn')
    end

    it 'возвращает Козерога для 5 января' do
      expect(described_class.by_date(Date.new(2001, 1, 5))[:key]).to eq('capricorn')
    end

    it 'возвращает Овна ровно на границе — 21 марта' do
      expect(described_class.by_date(Date.new(2000, 3, 21))[:key]).to eq('aries')
    end

    it 'возвращает Рыб ровно на границе — 20 марта' do
      expect(described_class.by_date(Date.new(2000, 3, 20))[:key]).to eq('pisces')
    end

    it 'возвращает nil для не-даты' do
      expect(described_class.by_date('not a date')).to be_nil
    end
  end

  describe '.find_by_name' do
    it 'находит по русскому названию с учётом регистра' do
      expect(described_class.find_by_name('Лев')[:key]).to eq('leo')
    end

    it 'находит по ключу' do
      expect(described_class.find_by_name('leo')[:key]).to eq('leo')
    end

    it 'не находит мусор' do
      expect(described_class.find_by_name('квазиморо')).to be_nil
    end
  end

  describe '.format' do
    it 'возвращает эмодзи + название' do
      leo = described_class.find('leo')
      expect(described_class.format(leo)).to eq('♌ Лев')
    end
  end
end
