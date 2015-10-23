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
        it 'unpacks all the parameters correctly' do
          expect(message.packet_length).to eq(29)
          expect(message.message_type).to eq(1)
          expect(message.bgp_version).to eq(4)
          expect(message.sender_as).to eq(30)
          expect(message.hold_time).to eq(180)
          expect(message.sender_id).to eq([10, 0, 0, 9].pack('CCCC'))
          expect(message.optional_parameters).to eq([])
        end
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

    context 'with an update messge' do
      let(:packet_length) { [71].pack('S>') }
      let(:message_type) { [2].pack('C') }
      let(:withdrawn_routes_length) { [4].pack('S>') }
      let(:withdrawn_routes) { "\x18\x0a\x01\x01" }
      let(:withdrawn_route1) { SliceIPPrefix.new([10, 1, 1, 0], 24) }
      let(:path_attributes_length) { [40].pack('S>') }
      let(:path_attributes) { "\x40\x01\x01\x02\x40\x02\x0a\x02\x01\x00\x1e\x01\x02\x00\x0a\x00\x14\x40\x03\x04\x0a\x00\x00\x09\x80\x04\x04\x00\x00\x00\x00\xc0\x07\x06\x00\x1e\x0a\x00\x00\x09".force_encoding('ASCII-8BIT') }
      let(:nlri) { "\x15\xac\x10\x00".force_encoding('ASCII-8BIT') }
      let(:update_packet) {
        valid_bgp_marker +
        packet_length +
        message_type +
        withdrawn_routes_length +
        withdrawn_routes +
        path_attributes_length +
        path_attributes +
        nlri
      }
      let(:raw_packet_data) { update_packet }

      context 'with valid parameters' do
        it 'unpacks all the parameters correctly' do
          expect(message.message_type).to eq(2)
          expect(message.withdrawn_routes[0].prefix).to eq(withdrawn_route1.prefix)
          expect(message.withdrawn_routes[0].prefix_length).to eq(withdrawn_route1.prefix_length)
          expect(message.path_attributes.length).to eq(5)
          #TODO test path attribute fields?
          expect(message.nlri.length).to eq(1)
          #expect(message.nlri).to eq("\x15\xac\x10\x00".force_encoding('ASCII-8BIT'))
        end
      end

      context 'with bad length' do
      end
    end

    context 'with a valid keepalive message' do
      let(:valid_keepalive_packet) { valid_bgp_marker + [19, 4].pack('S>C') }
      let(:raw_packet_data) { valid_keepalive_packet }
      
      it { is_expected.to be_a_kind_of BGPMessageKeepalive }
    end
  end
end
