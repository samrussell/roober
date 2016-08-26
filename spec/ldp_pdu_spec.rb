require 'spec_helper'
require 'ldp_pdu'
require 'stringio'
require 'string_slicer'
require 'json'

RSpec.describe LDPPDUPacked do
  let(:pdu1) do
    version = 1
    router = 0x12345678
    label = 0xabcd
    data = 23.times.map { 0xff }.pack("C*")
    pdu_length = 4 + 2 + 23 # length of router + label + data
    [version, pdu_length, router, label].pack("S>S>L>S>") + data
  end

  let(:pdu2) do
    version = 3
    router = 0x23456789
    label = 0xcdef
    data = 12.times.map { 0xff }.pack("C*")
    pdu_length = 4 + 2 + 12 # length of router + label + data
    [version, pdu_length, router, label].pack("S>S>L>S>") + data
  end

  let(:bytes) { pdu1 + pdu2 }
  let(:serialised_pdu_stream) { StringIO.new(bytes)}

  # TODO these packed classes are getting repetitive, find a better pattern

  it 'breaks up real PDUs' do
    expect(LDPPDUPacked.new(serialised_pdu_stream).call).to eq(pdu1)
    expect(LDPPDUPacked.new(serialised_pdu_stream).call).to eq(pdu2)
  end
end

RSpec.describe LDPPDU do
  let(:pdu_version) { "\x00\x01".force_encoding('ASCII-8BIT') }
  let(:lsr_id) { [10, 0, 0, 1].pack("CCCC") }
  let(:label_space_id) { [0x15].pack("S>") }
  let(:message1) { "\x01\x00\x00\x14\x00\x00\x00\x00\x04\x00\x00\x04\x00\x0f\x00\x00\x04\x01\x00\x04\x0a\x00\x01\x01".force_encoding('ASCII-8BIT') }
  let(:message2) { "\x01\x00\x00\x14\x00\x00\x00\x00\x04\x00\x00\x04\x00\x0f\x00\x00\x04\x01\x00\x04\x0a\x00\x01\x01".force_encoding('ASCII-8BIT') }
  let(:message3) { "\x01\x00\x00\x14\x00\x00\x00\x00\x04\x00\x00\x04\x00\x0f\x00\x00\x04\x01\x00\x04\x0a\x00\x01\x01".force_encoding('ASCII-8BIT') }
  let(:pdu_body) { message1 + message2 + message3 }
  let(:pdu_length) { [pdu_body.length + lsr_id.length + label_space_id.length].pack('S>') }
  let(:packed_pdu) { pdu_version + pdu_length + lsr_id + label_space_id + pdu_body }
  let(:pdu) { LDPPDU.build_from_packet(packed_pdu) }
  let(:repacked_pdu) { pdu.pack }

  describe '.build_from_packet' do
    it 'unpacks the PDU and its contents' do
      expect(pdu.version).to eq(1)
      expect(pdu.lsr_id).to eq(0x0a000001)
      expect(pdu.label_space_id).to eq(0x15)
      expect(pdu.messages.size).to eq(3)
    end
  end

  describe '#pack' do
    it 'packs the PDU and its contents' do
      expect(repacked_pdu).to eq(packed_pdu)
    end
  end
end
