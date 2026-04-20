# frozen_string_literal: true

require 'tmpdir'

RSpec.describe HoroscopeBot::Storage::JsonStore do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:path) { File.join(tmp_dir, 'test.json') }
  let(:store) { described_class.new(path) }

  after { FileUtils.rm_rf(tmp_dir) }

  describe '#write и #read' do
    it 'сохраняет и читает значение' do
      store.write('k', { 'value' => 42 })
      expect(store.read('k')).to eq('value' => 42)
    end

    it 'приводит ключ к строке' do
      store.write(123, 'hello')
      expect(store.read('123')).to eq('hello')
    end

    it 'возвращает nil для несуществующего ключа' do
      expect(store.read('missing')).to be_nil
    end
  end

  describe '#exists?' do
    it 'возвращает true, если ключ есть' do
      store.write('k', 'v')
      expect(store.exists?('k')).to be true
    end

    it 'возвращает false для отсутствующего ключа' do
      expect(store.exists?('k')).to be false
    end
  end

  describe '#delete' do
    it 'удаляет ключ' do
      store.write('k', 'v')
      store.delete('k')
      expect(store.exists?('k')).to be false
    end
  end

  describe 'персистентность' do
    it 'данные сохраняются между экземплярами (перезапуск бота)' do
      store.write('k', 'persisted')

      fresh_store = described_class.new(path)
      expect(fresh_store.read('k')).to eq('persisted')
    end
  end

  describe 'устойчивость' do
    it 'не падает на битом JSON-файле, а возвращает пустой набор' do
      File.write(path, 'this is not json')
      expect(store.read('anything')).to be_nil
    end

    it 'создаёт файл при отсутствии' do
      missing_path = File.join(tmp_dir, 'does_not_exist.json')
      described_class.new(missing_path)
      expect(File.exist?(missing_path)).to be true
    end
  end
end
