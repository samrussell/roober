require 'spec_helper'
require './lib/bgp_state_machine'

describe BGPStateMachine do
  subject(:bgp_state_machine) { BGPStateMachine.new }

  it 'starts in the idle state' do
    expect(bgp_state_machine.state).to eq(:idle)
  end

  context 'when it receives a valid Open message' do
    it 'transitions to the Active state'
  end
end
