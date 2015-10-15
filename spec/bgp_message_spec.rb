require 'spec_helper'
require 'bgp_message'

RSpec.describe BGPMessage do
  describe '.build_from_packet' do
    # packet samples found at http://packetlife.net/captures/protocol/bgp/
    # https://www.cloudshark.org/captures/004f81c952b7
    # and at RFC https://www.ietf.org/rfc/rfc4271.txt
    let(:raw_packet_data) { nil }
    let(:valid_bgp_marker) { ([0xff] * 16).pack("C" * 16) }
    let(:invalid_bgp_marker) { ([0xff] * 8 + [0x12] + [0xff] * 7).pack("C" * 16) }
    subject(:message) { BGPMessage.build_from_packet(raw_packet_data) }

    context 'without all 0xFF in the first 16 bytes data' do
      let(:invalid_keepalive_packet) { invalid_bgp_marker + "\x00\x13" + "\x04" }
      let(:raw_packet_data) { invalid_keepalive_packet }
      
      it 'throws an exception' do
        expect { BGPMessage.build_from_packet(raw_packet_data) }.to raise_error ArgumentError
      end
    end

    context 'with an open message' do
      let(:packet_length) { [29].pack('S>') }
      let(:message_type) { [1].pack('C') }
      let(:bgp_version) { [4].pack('C') }
      let(:sender_as) { [30].pack('S>') }
      let(:hold_time) { [180].pack('S>') }
      let(:sender_id) { [10, 0, 0, 9].pack('CCCC') }
      let(:optional_parameters_length) { [0].pack('C') }
      let(:optional_parameters) { '' }
      let(:open_packet) {
        valid_bgp_marker +
        packet_length +
        message_type +
        bgp_version +
        sender_as +
        hold_time +
        sender_id +
        optional_parameters_length +
        optional_parameters
      }
      let(:raw_packet_data) { open_packet }

      context 'with valid parameters' do
        it { is_expected.to be_a_kind_of BGPMessageOpen }
      end

      context 'with bad length' do
        let(:packet_length) { [28].pack('S>') }
        let(:raw_packet_data) { open_packet }
        
        it 'throws an exception with :bgp_open_bad_length' do
          expect { BGPMessage.build_from_packet(raw_packet_data) }.to raise_error do |error|
            expect(error.suberror).to eq(:bgp_open_bad_length)
          end
        end
      end

      context 'with bad version' do
        let(:bgp_version) { [9].pack('C') }
        let(:raw_packet_data) { open_packet }
        
        it 'throws an exception with :bgp_open_bad_version' do
          expect { BGPMessage.build_from_packet(raw_packet_data) }.to raise_error do |error|
            expect(error.suberror).to eq(:bgp_open_bad_version)
          end
        end
      end

      context 'with bad hold time' do
        # The Hold Time MUST be either zero or at least three seconds
        let(:hold_time) { [2].pack('S>') }
        let(:raw_packet_data) { open_packet }
        
        it 'throws an exception with :bgp_open_bad_hold_time' do
          expect { BGPMessage.build_from_packet(raw_packet_data) }.to raise_error do |error|
            expect(error.suberror).to eq(:bgp_open_bad_hold_time)
          end
        end
      end

      context 'with bad optional parameters length' do
        let(:optional_parameters_length) { [3].pack('C') }
        let(:raw_packet_data) { open_packet }
        
        it 'throws an exception with :bgp_open_bad_optional_parameters_length' do
          expect { BGPMessage.build_from_packet(raw_packet_data) }.to raise_error do |error|
            expect(error.suberror).to eq(:bgp_open_bad_optional_parameters_length)
          end
        end
      end
    end

    context 'with a valid keepalive message' do
      let(:valid_keepalive_packet) { valid_bgp_marker + [19, 4].pack('S>C') }
      let(:raw_packet_data) { valid_keepalive_packet }
      
      it { is_expected.to be_a_kind_of BGPMessageKeepalive }
    end
  end
end
