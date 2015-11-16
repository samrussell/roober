require 'spec_helper'
require 'tlv'

RSpec.describe TLV do
  let(:tlv_code) { 5 }
  let(:tlv_length) { 20 }
  let(:tlv_data) { [*1..20].pack('C*') }
  let(:tlv_code_packed) { [tlv_code].pack('C') }
  let(:tlv_length_packed) { [tlv_length].pack('C') }
  let(:packed_tlv) {
    tlv_code_packed +
    tlv_length_packed +
    tlv_data
  }

  describe '.unpack' do
    let(:tlv) { TLV.unpack(packed_tlv) }

    it 'has code and data that match the binary' do
      expect(tlv.code).to eq(tlv_code)
      expect(tlv.data.length).to eq(tlv_length)
      expect(tlv.data).to eq(tlv_data)
    end

    it 'packs to the original' do
      expect(tlv.pack).to eq(packed_tlv)
    end

    context 'with bad length' do
      let(:tlv_length) { 21 }

      it 'throws an error' do
        expect {
          TLV.unpack(packed_tlv)
        }.to raise_error ArgumentError
      end
    end
  end
end
