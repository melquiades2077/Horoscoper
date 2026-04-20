# frozen_string_literal: true

require 'tmpdir'

RSpec.describe HoroscopeBot::Storage::UserRepository do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:store) { HoroscopeBot::Storage::JsonStore.new(File.join(tmp_dir, 'u.json')) }
  let(:repo) { described_class.new(store) }

  after { FileUtils.rm_rf(tmp_dir) }

  it 'находит пустой хэш для нового пользователя' do
    expect(repo.find('42')).to eq({})
  end

  it 'сохраняет знак и читает его обратно' do
    repo.set_sign('42', 'leo')
    expect(repo.sign('42')).to eq('leo')
  end

  it 'merge-ит атрибуты, не перезаписывая всё' do
    repo.save('42', sign: 'leo')
    repo.save('42', birthdate: '1995-08-15')
    profile = repo.find('42')
    expect(profile['sign']).to eq('leo')
    expect(profile['birthdate']).to eq('1995-08-15')
  end
end
