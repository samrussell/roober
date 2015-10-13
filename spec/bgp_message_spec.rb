require 'spec_helper'
require 'bgp_message'

RSpec.describe BGPMessage do
  describe '#build_from_packet' do
    let(:raw_packet_data) { nil }
    subject(:message) { BGPMessage.build_from_packet(raw_packet_data) }

    context 'with invalid leading data' do
      # need a cleaner way to mark out these packets
      let(:raw_packet_data) { "\xFF" * 8 + "\x12" + "\xFF" * 7 + "\x00\x13" + "\x04" }
      
      it { is_expected.to be nil }
    end

    context 'with a valid keepalive message' do
      let(:raw_packet_data) { "\xFF" * 16 + "\x00\x13" + "\x04" }
      
      it { is_expected.to be_a_kind_of BGPMessageKeepalive }
    end
  end
end
