# frozen_string_literal: true

RSpec.describe HoroscopeBot::Services::AffirmationGenerator do
  let(:date) { Date.new(2025, 6, 15) }

  it 'возвращает текст с выбранной сферой и тоном' do
    text = described_class.new(date:).generate(user_id: '42', topic_key: 'love', tone_key: 'soft')
    expect(text).to include('Аффирмация дня')
    expect(text).to include('15.06.2025')
    expect(text).to include('Сфера: Любовь')
    expect(text).to include('Тон:')
  end

  it 'детерминирован для одинаковых входных данных' do
    a = described_class.new(date:).generate(user_id: '42', topic_key: 'career', tone_key: 'strong')
    b = described_class.new(date:).generate(user_id: '42', topic_key: 'career', tone_key: 'strong')
    expect(a).to eq(b)
  end

  it 'даёт разные тексты для разных тонов' do
    soft = described_class.new(date:).generate(user_id: '42', topic_key: 'energy', tone_key: 'soft')
    strong = described_class.new(date:).generate(user_id: '42', topic_key: 'energy', tone_key: 'strong')
    expect(soft).not_to eq(strong)
  end

  it 'бросает ошибку для неизвестной сферы' do
    expect do
      described_class.new(date:).generate(user_id: '42', topic_key: 'unknown', tone_key: 'soft')
    end.to raise_error(ArgumentError, /Неизвестная сфера/)
  end
end
