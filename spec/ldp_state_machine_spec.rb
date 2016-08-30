require 'spec_helper'
require './lib/ldp_message'
require './lib/ldp_state_machine'
require './lib/mailbox'

describe LDPStateMachine do
  let(:mock_ldp_keepalive_message) { instance_double(LDPMessageKeepalive, :message_type => LDPMessageKeepalive::MESSAGE_CODE) }
  let(:mock_ldp_initialise_message) { instance_double(LDPMessageInitialization, :message_type => LDPMessageInitialization::MESSAGE_CODE, :message_id => 123) }
  let(:mailbox) { instance_double('Mailbox') }
  subject(:ldp_state_machine) { LDPStateMachine.new(mailbox) }

  it 'starts in the non_existent state' do
    expect(ldp_state_machine.state).to eq(:non_existent)
  end

  context 'passive mode' do
    context 'when in the non_existent state' do
      context 'when it receives a TCP connection confirmed event' do
        it 'transitions to the initialised state' do
          expect { ldp_state_machine.event(:tcp_connection_confirmed) }.to change { ldp_state_machine.state }.from(:non_existent).to(:initialised)
        end
      end
    end

    context 'when in the initialised state' do
      before do
        ldp_state_machine.event(:tcp_connection_confirmed)
      end

      context 'when it receives an Initialization message' do
        it 'sends an initialisation message followed by a keepalive message and transitions to the openrec state' do
          expect(mailbox).to receive(:send_message).ordered.with(a_kind_of(LDPMessageInitialization))
          expect(mailbox).to receive(:send_message).ordered.with(a_kind_of(LDPMessageKeepalive))
          expect(ldp_state_machine.state).to eq(:initialised)

          ldp_state_machine.message(mock_ldp_initialise_message)

          expect(ldp_state_machine.state).to eq(:openrec)
        end
      end
    end

    context 'when in the Openrec state' do
      before do
        allow(mailbox).to receive(:send_message).ordered.with(a_kind_of(LDPMessageInitialization))
        allow(mailbox).to receive(:send_message).ordered.with(a_kind_of(LDPMessageKeepalive))

        ldp_state_machine.event(:tcp_connection_confirmed)
        ldp_state_machine.message(mock_ldp_initialise_message)
      end

      context 'when it receives a Keepalive message' do
        it 'transitions to the Operational state' do
          expect(ldp_state_machine.state).to eq(:openrec)

          expect { ldp_state_machine.message(mock_ldp_keepalive_message) }.to change { ldp_state_machine.state }.from(:openrec).to(:operational)
        end
      end
    end
  end
end
