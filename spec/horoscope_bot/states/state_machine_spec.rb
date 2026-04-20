# frozen_string_literal: true

require 'tmpdir'

RSpec.describe HoroscopeBot::States::StateMachine do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:store) { HoroscopeBot::Storage::JsonStore.new(File.join(tmp_dir, 's.json')) }
  let(:fsm) { described_class.new(store) }

  after { FileUtils.rm_rf(tmp_dir) }

  it 'новый пользователь находится в idle' do
    expect(fsm.get('42')).to be_idle
  end

  it 'set сохраняет состояние с контекстом' do
    fsm.set('42', HoroscopeBot::States::UserState::AWAITING_BIRTHDATE, { 'attempt' => 1 })
    state = fsm.get('42')
    expect(state.name).to eq('awaiting_birthdate')
    expect(state.context).to eq('attempt' => 1)
  end

  it 'update_context сливает контекст, не ломая name' do
    fsm.set('42', HoroscopeBot::States::UserState::AWAITING_COMPATIBILITY_FIRST, { 'a' => 1 })
    fsm.update_context('42', b: 2)
    state = fsm.get('42')
    expect(state.name).to eq('awaiting_compatibility_first')
    expect(state.context).to include('a' => 1, 'b' => 2)
  end

  it 'reset возвращает в idle' do
    fsm.set('42', HoroscopeBot::States::UserState::AWAITING_BIRTHDATE)
    fsm.reset('42')
    expect(fsm.get('42')).to be_idle
  end

  it 'состояния персистентны (имитация перезапуска бота)' do
    fsm.set('42', HoroscopeBot::States::UserState::AWAITING_BIRTHDATE, { 'x' => 'y' })

    fresh_store = HoroscopeBot::Storage::JsonStore.new(store.instance_variable_get(:@path))
    fresh_fsm = described_class.new(fresh_store)
    expect(fresh_fsm.get('42').name).to eq('awaiting_birthdate')
    expect(fresh_fsm.get('42').context).to eq('x' => 'y')
  end

  it 'отвергает неизвестное имя состояния' do
    expect { fsm.set('42', 'lol_unknown') }.to raise_error(ArgumentError)
  end
end
