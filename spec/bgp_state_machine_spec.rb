require 'spec_helper'
require './lib/bgp_state_machine'
require './lib/bgp_message'
require './lib/mailbox'

describe BGPStateMachine do
  let(:mailbox) { instance_double('Mailbox') }
  subject(:bgp_state_machine) { BGPStateMachine.new(mailbox) }

  it 'starts in the idle state' do
    expect(bgp_state_machine.state).to eq(:idle)
  end

  context 'when in the idle state' do
    context 'when it receives a ManualStart event' do
      # handle in next story
      xit 'transitions to the connect state' do
        expect { bgp_state_machine.event(:manual_start) }.to change { bgp_state_machine.state }.from(:idle).to(:connect)
      end
    end

    context 'when it receives a ManualStartPassive event' do
      context 'passive' do
        it 'transitions to the active state' do
          expect { bgp_state_machine.event(:manual_start_passive) }.to change { bgp_state_machine.state }.from(:idle).to(:active)
        end
      end
    end
  end

  context 'when in the Active state' do
    before do
      bgp_state_machine.event(:manual_start_passive)
    end

    context 'when it receives a TcpConnectionConfirmed event' do
      it 'doesn\'t change state' do
        expect(bgp_state_machine.state).to eq(:active)

        expect { bgp_state_machine.event(:tcp_connection_confirmed) }.to_not change { bgp_state_machine.state }
      end
    end

    context 'when it receivs a valid Open message' do
      let(:mock_bgp_open_message) { instance_double(BGPMessageOpen) }

      before do
        allow(mock_bgp_open_message).to receive(:message_type).and_return(BGPMessageOpen::MESSAGE_CODE)
      end

      it 'sends an open message, a keepalive message, and changes state to OpenConfirm' do
        # TODO send messages
        expect(bgp_state_machine.state).to eq(:active)
        
        expect(mailbox).to receive(:send_message).with a_kind_of(BGPMessageOpen)
        expect(mailbox).to receive(:send_message).with a_kind_of(BGPMessageKeepalive)

        bgp_state_machine.message(mock_bgp_open_message)

        expect(bgp_state_machine.state).to eq(:open_confirm)
      end
    end
  end

  context 'when in the Connect state' do
    # handle in next story
    before do
      bgp_state_machine.event(:manual_start)
    end

    xcontext 'when it receives a TcpConnectionConfirmed event' do
      it 'sends a BGP Open message to the peer' do
      end

      it 'transitions to the OpenSent state' do
        expect { bgp_state_machine.event(:tcp_connection_confirmed) }.to change { bgp_state_machine.state }.from(:connect).to(:open_sent)
      end
    end
  end

  # handle in next story
  xcontext 'when in the opensent state' do
    context 'when it receives a valid Open message' do
      it 'transitions to the Active state'
    end

    context 'when it receives an invalid Open message' do
      it 'sends a notification message and closes the connection'
    end
  end
end
