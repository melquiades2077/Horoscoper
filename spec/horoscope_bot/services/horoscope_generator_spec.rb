# frozen_string_literal: true

RSpec.describe HoroscopeBot::Services::HoroscopeGenerator do
  let(:date) { Date.new(2025, 6, 15) }
  subject(:generator) { described_class.new(date: date) }

  it 'возвращает текст, содержащий название знака' do
    expect(generator.generate('leo')).to include('Лев')
  end

  it 'содержит дату в читаемом формате' do
    expect(generator.generate('leo')).to include('15.06.2025')
  end

  it 'детерминирован для одной пары (знак, дата)' do
    a = described_class.new(date: date).generate('aries')
    b = described_class.new(date: date).generate('aries')
    expect(a).to eq(b)
  end

  it 'даёт разные результаты для разных знаков' do
    aries = generator.generate('aries')
    pisces = generator.generate('pisces')
    expect(aries).not_to eq(pisces)
  end

  it 'даёт разные результаты для разных дат' do
    today = described_class.new(date: Date.new(2025, 6, 15)).generate('leo')
    tomorrow = described_class.new(date: Date.new(2025, 6, 16)).generate('leo')
    expect(today).not_to eq(tomorrow)
  end

  it 'бросает ArgumentError для несуществующего знака' do
    expect { generator.generate('pokemon') }.to raise_error(ArgumentError)
  end
end
