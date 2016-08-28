require 'spec_helper'
require 'ldp_parameter'
require 'stringio'
require 'string_slicer'
require 'json'

# TODO shared examples for TLV subclasses

RSpec.describe LDPParameterIPv4Address do
  let(:code) { [0x0401].pack("S>") }
  let(:length) { [4].pack("S>") }
  let(:address) { [10, 1, 1, 1].pack("CCCC") }
  let(:packed_parameter) { code + length + address }
  let(:parameter) { LDPParameter.build_from_packet(packed_parameter) }
  let(:repacked_parameter) { parameter.pack }

  describe '.build_from_packet' do
    it 'unpacks the parameter' do
      expect(parameter.address.to_s).to eq("10.1.1.1")
    end
  end

  describe '#pack' do
    it 'packs the parameter' do
      expect(repacked_parameter).to eq(packed_parameter)
    end
  end
end

