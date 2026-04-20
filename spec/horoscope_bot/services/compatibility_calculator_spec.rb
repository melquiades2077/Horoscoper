# frozen_string_literal: true

RSpec.describe HoroscopeBot::Services::CompatibilityCalculator do
  subject(:calc) { described_class.new }

  it 'возвращает высокую совместимость для Овна и Льва (оба огонь)' do
    result = calc.calculate('aries', 'leo')
    score = result.match(/Результат: (\d+)%/)[1].to_i
    expect(score).to be >= 80
  end

  it 'возвращает текст, содержащий оба знака' do
    result = calc.calculate('aries', 'libra')
    expect(result).to include('Овен')
    expect(result).to include('Весы')
  end

  it 'детерминирован — одни и те же аргументы дают тот же результат' do
    expect(calc.calculate('leo', 'aquarius')).to eq(calc.calculate('leo', 'aquarius'))
  end

  it 'симметричен по оценке (Лев+Рак = Рак+Лев)' do
    a = calc.calculate('leo', 'cancer').match(/(\d+)%/)[1]
    b = calc.calculate('cancer', 'leo').match(/(\d+)%/)[1]
    expect(a).to eq(b)
  end

  it 'бросает ошибку для неизвестного знака' do
    expect { calc.calculate('leo', 'unknown') }.to raise_error(ArgumentError)
  end
end
