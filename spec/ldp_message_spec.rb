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


RSpec.describe LDPMessage do
  describe '.build_from_packet' do
    context 'hello message' do
      let(:packed_message) { "\x01\x00\x00\x14\x00\x00\x00\x17\x04\x00\x00\x04\x00\x5a\xc0\x00\x04\x01\x00\x04\x0a\x09\x09\x01" }
      subject(:hello_message) { LDPMessage.build_from_packet(packed_message) }

      it 'unpacks the message' do
        expect(hello_message.message_id).to eq(0x17000000)
      end
    end
  end
end
