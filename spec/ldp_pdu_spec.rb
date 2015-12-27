require 'spec_helper'
require 'ldp_pdu'
require 'stringio'
require 'string_slicer'
require 'json'

RSpec.describe LDPPDUPacked do
  let(:first2bytes) { [0x00.chr, 0x01.chr].join }
  let(:message1_length) { 20 }
  let(:message1) { first2bytes + [message1_length].pack("S>") + 20.times.map { 69.chr }.join }
  let(:message2_length) { 30 }
  let(:message2) { first2bytes + [message2_length].pack("S>") + 30.times.map { 69.chr }.join }
  let(:message3_length) { 100 }
  let(:message3) { first2bytes + [message3_length].pack("S>") + 100.times.map { 69.chr }.join }
  let(:serialised_messages) { message1 + message2 + message3 }
  let(:serialised_message_stream) { StringIO.new(serialised_messages) }

  it 'breaks up messages correctly' do
    expect(LDPPDUPacked.new(serialised_message_stream).call).to eq(message1)
    expect(LDPPDUPacked.new(serialised_message_stream).call).to eq(message2)
    expect(LDPPDUPacked.new(serialised_message_stream).call).to eq(message3)
  end
end
