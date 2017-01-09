require 'spec_helper'
require 'ldp_message'
require 'stringio'
require 'string_slicer'
require 'json'

RSpec.describe LDPMessagePacked do
  let(:first2bytes) { [0x01.chr, 0x00.chr].join }
  let(:message1_length) { 20 }
  let(:message1) { first2bytes + [message1_length].pack("S>") + 20.times.map { 69.chr }.join }
  let(:message2_length) { 30 }
  let(:message2) { first2bytes + [message2_length].pack("S>") + 30.times.map { 69.chr }.join }
  let(:message3_length) { 100 }
  let(:message3) { first2bytes + [message3_length].pack("S>") + 100.times.map { 69.chr }.join }
  let(:serialised_messages) { message1 + message2 + message3 }
  let(:serialised_message_stream) { StringIO.new(serialised_messages) }

  it 'breaks up messages correctly' do
    expect(LDPMessagePacked.new(serialised_message_stream).call).to eq(message1)
    expect(LDPMessagePacked.new(serialised_message_stream).call).to eq(message2)
    expect(LDPMessagePacked.new(serialised_message_stream).call).to eq(message3)
  end
end


RSpec.describe LDPMessageHello do
  let(:message_type) { [0x100].pack("S>") }
  let(:message_length) { [20].pack("S>") }
  let(:message_id) { [0x17].pack("L>") }
  let(:common_parameters) {
    [0x400].pack("S>") +
    [4].pack("S>") +
    [90].pack("S>") +
    [0xc000].pack("S>")
  }
  let(:ipv4_parameter) {
    [0x401].pack("S>") +
    [4].pack("S>") +
    [10, 1, 1, 1].pack("CCCC")
  }
  let(:packed_message) { message_type + message_length + message_id + common_parameters + ipv4_parameter }
  let(:hello_message) { LDPMessage.build_from_packet(packed_message) }
  let(:repacked_message) { hello_message.pack }

  describe '.build_from_packet' do

    it 'unpacks the message' do
      expect(hello_message.message_id).to eq(0x17)
      expect(hello_message.hold_time).to eq(90)
      expect(hello_message.targeted?).to be true
      expect(hello_message.request_targeted?).to be true
    end
  end

  describe '#pack' do
    it 'packs the message' do
      expect(repacked_message).to eq(packed_message)
    end
  end
end

RSpec.describe LDPMessageInitialization do
  let(:packed_message) { "\x02\x00\x00\x16\x00\x00\x00\x01\x05\x00\x00\x0e\x00\x01\x00\xb4\x00\x00\x00\x00\x0a\x00\x01\x01\x00\x00".force_encoding('ASCII-8BIT') }
  let(:initialization_message) { LDPMessage.build_from_packet(packed_message) }
  let(:repacked_message) { initialization_message.pack }
  describe '.build_from_packet' do
    context 'initialization message' do
      it 'unpacks the message' do
        expect(initialization_message.message_id).to eq(1)
        expect(initialization_message.protocol_version).to eq(1)
        expect(initialization_message.keepalive_time).to eq(180)
        expect(initialization_message.flags).to eq(0)
        expect(initialization_message.path_vector_limit).to eq(0)
        expect(initialization_message.max_pdu_length).to eq(0)
        expect(initialization_message.lsr_id.to_s).to eq("10.0.1.1")
        expect(initialization_message.label_space_id).to eq(0)
      end
    end
  end

  describe '#pack' do
    it 'packs the message' do
      expect(repacked_message).to eq(packed_message)
    end
  end
end

RSpec.describe LDPMessageKeepalive do
  let(:message_type) { [0x201].pack("S>") }
  let(:message_length) { [4].pack("S>") }
  let(:message_id) { [0x3].pack("L>") }
  let(:packed_message) { message_type + message_length + message_id }
  let(:keepalive_message) { LDPMessage.build_from_packet(packed_message) }
  let(:repacked_message) { keepalive_message.pack }
  describe '.build_from_packet' do
    context 'keepalive message' do
      it 'unpacks the message' do
        expect(keepalive_message.message_id).to eq(3)
      end
    end
  end

  describe '#pack' do
    it 'packs the message' do
      expect(repacked_message).to eq(packed_message)
    end
  end
end

RSpec.describe LDPMessageAddress do
  let(:message_type) { [0x300].pack("S>") }
  let(:message_length) { [4 + address_tlv.length].pack("S>") }
  let(:message_id) { [0x3].pack("L>") }
  let(:address_tlv) {
    [0x101].pack("S>") +
    [10].pack("S>") +
    [1].pack("S>") +
    [10, 1, 1, 1].pack("CCCC") +
    [192, 168, 1, 1].pack("CCCC")
  }
  let(:packed_message) { message_type + message_length + message_id + address_tlv }
  let(:address_message) { LDPMessage.build_from_packet(packed_message) }
  let(:repacked_message) { address_message.pack }
  describe '.build_from_packet' do
    context 'address message' do
      it 'unpacks the message' do
        expect(address_message.message_id).to eq(3)
        expect(address_message.address_list.addresses.map(&:to_s)).to eq(["10.1.1.1", "192.168.1.1"])
      end
    end
  end

  describe '#pack' do
    it 'packs the message' do
      expect(repacked_message).to eq(packed_message)
    end
  end
end

RSpec.describe LDPMessageLabelMapping do
  # 0400
  # 0018
  # 00000a4e
  # 010000080200011e0a0a0a00
  # 0200000400000003
  let(:message_type) { [0x400].pack("S>") }
  let(:message_length) { [24].pack("S>") }
  let(:message_id) { [0x3].pack("L>") }
  # TODO build properly
  let(:body) { "\x01\x00\x00\x08\x02\x00\x01\x1e\x0a\x0a\x0a\x00\x02\x00\x00\x04\x00\x00\x00\x03" }
  let(:packed_message) { message_type + message_length + message_id + body }
  let(:label_message) { LDPMessage.build_from_packet(packed_message) }
  let(:repacked_message) { label_message.pack }
  describe '.build_from_packet' do
    context 'label message' do
      it 'unpacks the message' do
        expect(label_message.message_id).to eq(3)
        expect(label_message.prefixes.first.address).to eq(IPAddr.new("10.10.10.0/30"))
        expect(label_message.prefixes.first.mask).to eq(30)
        expect(label_message.label).to eq(3)
      end
    end
  end

  describe '#pack' do
    it 'packs the message' do
      expect(repacked_message).to eq(packed_message)
    end
  end
end
