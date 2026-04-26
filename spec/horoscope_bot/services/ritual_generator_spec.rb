# frozen_string_literal: true

RSpec.describe HoroscopeBot::Services::RitualGenerator do
  let(:date) { Date.new(2025, 6, 15) }

  it 'возвращает читаемый текст с датой' do
    text = described_class.new(date:).generate('42')
    expect(text).to include('Ритуал дня')
    expect(text).to include('15.06.2025')
    expect(text).to include('Действие:')
    expect(text).to include('Фокус:')
    expect(text).to include('Лучшее время:')
  end

  it 'детерминирован для одного пользователя в один день' do
    a = described_class.new(date:).generate('42')
    b = described_class.new(date:).generate('42')
    expect(a).to eq(b)
  end

  it 'меняется для разных пользователей' do
    first = described_class.new(date:).generate('42')
    second = described_class.new(date:).generate('43')
    expect(first).not_to eq(second)
  end

  it 'меняется для разных дат' do
    today = described_class.new(date: Date.new(2025, 6, 15)).generate('42')
    tomorrow = described_class.new(date: Date.new(2025, 6, 16)).generate('42')
    expect(today).not_to eq(tomorrow)
  end
end
