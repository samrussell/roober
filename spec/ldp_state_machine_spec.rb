require 'spec_helper'
require './lib/ldp_state_machine'
require './lib/mailbox'

describe LDPStateMachine do
  let(:mailbox) { instance_double('Mailbox') }
  subject(:ldp_state_machine) { LDPStateMachine.new(mailbox) }

  it 'starts in the idle state' do
    expect(ldp_state_machine.state).to eq(:idle)
  end

  context 'when in the idle state' do
    context 'when it receives a ManualStartPassive event' do
      context 'passive' do
        it 'transitions to the active state' do
          expect { ldp_state_machine.event(:manual_start_passive) }.to change { ldp_state_machine.state }.from(:idle).to(:active)
        end
      end
    end
  end

  context 'when in the Active state' do
    before do
      ldp_state_machine.event(:manual_start_passive)
    end

    context 'when it receives a TcpConnectionConfirmed event' do
      it 'doesn\'t change state' do
        expect(ldp_state_machine.state).to eq(:active)

        expect { ldp_state_machine.event(:tcp_connection_confirmed) }.to_not change { ldp_state_machine.state }
      end
    end

    xcontext 'when it receivs a valid Open message' do
      let(:mock_ldp_open_message) { instance_double(LDPMessageOpen) }

      before do
        allow(mock_ldp_open_message).to receive(:message_type).and_return(LDPMessageOpen::MESSAGE_CODE)
      end

      it 'sends an open message, a keepalive message, and changes state to OpenConfirm' do
        expect(ldp_state_machine.state).to eq(:active)
        
        expect(mailbox).to receive(:send_message).with a_kind_of(LDPMessageOpen)
        expect(mailbox).to receive(:send_message).with a_kind_of(LDPMessageKeepalive)

        ldp_state_machine.message(mock_ldp_open_message)

        expect(ldp_state_machine.state).to eq(:open_confirm)
      end
    end
  end
end
