require 'spec_helper'
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

  context 'when in the Initialised state' do
    before do
      ldp_state_machine.event(:tcp_connection_confirmed)
    end

    context 'when it receives an Initialise event' do
      context 'passive' do
        it 'sends an initialisation message followed by a keepalive message' do
          expect(:mailbox).to receive(:send_message).with a_kind_of(LDPMessageInitialise).ordered
          expect(:mailbox).to receive(:send_message).with a_kind_of(LDPMessageKeepalive).ordered
        end

        it 'transitions to the openrec state' do
          expect(ldp_state_machine.state).to eq(:initialised)

          expect { ldp_state_machine.event(:initialise) }.to change { ldp_state_machine.state }.from(:initialised).to(:openrec)
        end
      end
    end
  end

  context 'when in the Openrec state' do
    before do
      ldp_state_machine.event(:tcp_connection_confirmed)
      ldp_state_machine.event(:initialise)
    end

    context 'when it receives a Keepalive event' do
      context 'passive' do
        it 'transitions to the Operational state' do
          expect(ldp_state_machine.state).to eq(:openrec)

          expect { ldp_state_machine.event(:keepalive) }.to change { ldp_state_machine.state }.from(:openrec).to(:operational)
        end
      end
    end
  end
end
