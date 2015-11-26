require 'spec_helper'
require 'bgp_message'
require 'stringio'
require 'string_slicer'
require 'json'

RSpec.describe BGPMessagePacked do
  let(:first16bytes) { 16.times.map {0xFF.chr}.join }
  let(:message1_length) { 20 }
  let(:message1) { first16bytes + [message1_length].pack("S>") + 2.times.map { 69.chr }.join }
  let(:message2_length) { 30 }
  let(:message2) { first16bytes + [message2_length].pack("S>") + 12.times.map { 69.chr }.join }
  let(:message3_length) { 100 }
  let(:message3) { first16bytes + [message3_length].pack("S>") + 82.times.map { 69.chr }.join }
  let(:serialised_messages) { message1 + message2 + message3 }
  let(:serialised_message_stream) { StringIO.new(serialised_messages) }

  it 'breaks up messages correctly' do
    expect(BGPMessagePacked.new(serialised_message_stream).call).to eq(message1)
    expect(BGPMessagePacked.new(serialised_message_stream).call).to eq(message2)
    expect(BGPMessagePacked.new(serialised_message_stream).call).to eq(message3)
  end
end

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

        it 'packs to the original' do
          expect(message.pack).to eq(raw_packet_data)
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

      # TODO handle optional parameters in their own tests
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
      let(:withdrawn_routes) { "\x18\x0a\x01\x01".force_encoding('ASCII-8BIT') }
      let(:withdrawn_route1) { SliceIPPrefix.new([10, 1, 1, 0], 24) }
      let(:path_attributes_length) { [40].pack('S>') }
      let(:path_attributes) { "\x40\x01\x01\x02\x40\x02\x0a\x02\x01\x00\x1e\x01\x02\x00\x0a\x00\x14\x40\x03\x04\x0a\x00\x00\x09\x80\x04\x04\x00\x00\x00\x00\xc0\x07\x06\x00\x1e\x0a\x00\x00\x09".force_encoding('ASCII-8BIT') }
      let(:nlri) { "\x15\xac\x10\x00".force_encoding('ASCII-8BIT') }
      let(:nlri1) { SliceIPPrefix.new([172, 16, 0, 0], 21) }
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
          expect(message.nlri[0].prefix).to eq(nlri1.prefix)
          expect(message.nlri[0].prefix_length).to eq(nlri1.prefix_length)
          #expect(message.nlri).to eq("\x15\xac\x10\x00".force_encoding('ASCII-8BIT'))
        end

        it 'serialises to JSON' do
          json_update_message = message.to_json

          parsed_json = JSON.parse(json_update_message)

          expect(parsed_json['nlri']).to contain_exactly(nlri1.to_s) 
          expect(parsed_json['withdrawn_routes']).to contain_exactly(withdrawn_route1.to_s)
        end

        it 'serialises to a string' do
          text_update_message = message.to_s

          expect(text_update_message).to eq("Withdrawn prefixes: 10.1.1.0/24\nNew prefixes: 172.16.0.0/21")
        end
      end

      context 'with bad length' do
        # TODO test this
      end
    end

    context 'with a valid keepalive message' do
      let(:valid_keepalive_packet) { valid_bgp_marker + [19, 4].pack('S>C') }
      let(:raw_packet_data) { valid_keepalive_packet }
      
      it { is_expected.to be_a_kind_of BGPMessageKeepalive }

      it 'packs to the original' do
        expect(subject.pack).to eq(raw_packet_data)
      end
    end
  end
end
