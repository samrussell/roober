require 'spec_helper'
require './lib/bgp_state_machine'

describe BGPStateMachine do
  subject(:bgp_state_machine) { BGPStateMachine.new }

  it 'starts in the idle state' do
    expect(bgp_state_machine.state).to eq(:idle)
  end

  context 'when in the idle state' do
    context 'when it receives a ManualStart event' do
      it 'transitions to the connect state' do
        expect { bgp_state_machine.event(:manual_start) }.to change { bgp_state_machine.state }.from(:idle).to(:connect)
      end
    end
    
    context 'when it receives a ManualStop event' do
    end
  end

  context 'when in the connect state' do
    context 'when it receives a valid Open message' do
      it 'transitions to the Active state'
    end

    context 'when it receives an invalid Open message' do
      it 'sends a notification message and closes the connection'
    end
  end
end
