require 'spec_helper'
require './lib/ldp_message'
require './lib/ldp_state_machine'
require './lib/mailbox'

describe LDPStateMachine do
  let(:mailbox) { instance_double('Mailbox') }
  subject(:ldp_state_machine) { LDPStateMachine.new(mailbox) }

  it 'starts in the non_existent state' do
    expect(ldp_state_machine.state).to eq(:non_existent)
  end

  context 'when in the non_existent state' do
    context 'when it receives a TCP connection confirmed event' do
      context 'passive' do
        it 'transitions to the initialised state' do
          expect { ldp_state_machine.event(:tcp_connection_confirmed) }.to change { ldp_state_machine.state }.from(:non_existent).to(:initialised)
        end
      end
    end
  end

  context 'when in the initialised state' do
    before do
      ldp_state_machine.event(:tcp_connection_confirmed)
    end

    context 'when it receives an Initialization message' do
      let(:mock_ldp_initialise_message) { instance_double(LDPMessageInitialization) }

      before do
        allow(mock_ldp_initialise_message).to receive(:message_type).and_return(LDPMessageInitialization::MESSAGE_CODE)
      end

      context 'passive' do
        it 'sends an initialisation message followed by a keepalive message and transitions to the openrec state' do
          expect(mailbox).to receive(:send_message).ordered.with(a_kind_of(LDPMessageInitialization))
          expect(mailbox).to receive(:send_message).ordered.with(a_kind_of(LDPMessageKeepalive))
          expect(ldp_state_machine.state).to eq(:initialised)

          ldp_state_machine.message(mock_ldp_initialise_message)

          expect(ldp_state_machine.state).to eq(:openrec)
        end
      end
    end
  end

  context 'when in the Openrec state' do
    let(:mock_ldp_initialise_message) { instance_double(LDPMessageInitialization) }
    let(:mock_ldp_keepalive_message) { instance_double(LDPMessageKeepalive) }

    before do
      # TODO set attr_readers in let block
      allow(mock_ldp_keepalive_message).to receive(:message_type).and_return(LDPMessageKeepalive::MESSAGE_CODE)
      allow(mock_ldp_initialise_message).to receive(:message_type).and_return(LDPMessageInitialization::MESSAGE_CODE)

      allow(mailbox).to receive(:send_message).ordered.with(a_kind_of(LDPMessageInitialization))
      allow(mailbox).to receive(:send_message).ordered.with(a_kind_of(LDPMessageKeepalive))

      ldp_state_machine.event(:tcp_connection_confirmed)
      ldp_state_machine.message(mock_ldp_initialise_message)
    end

    context 'when it receives a Keepalive message' do
      context 'passive' do
        it 'transitions to the Operational state' do
          expect(ldp_state_machine.state).to eq(:openrec)

          expect { ldp_state_machine.message(mock_ldp_keepalive_message) }.to change { ldp_state_machine.state }.from(:openrec).to(:operational)
        end
      end
    end
  end
end
