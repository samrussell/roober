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

RSpec.describe LDPParameterCommonSession do
  let(:code) { [0x0500].pack("S>") }
  let(:length) { [14].pack("S>") }
  let(:protocol_version) { [1].pack("S>") }
  let(:keepalive_time) { [15].pack("S>") }
  let(:flags) { [0].pack("C") }
  let(:path_vector_limit) { [0].pack("C") }
  let(:max_pdu_length) { [0].pack("S>") }
  let(:lsr_id) { [10, 1, 1, 1].pack("CCCC") }
  let(:label_space_id) { [0].pack("S>") }
  let(:packed_parameter) {  code +
                            length +
                            protocol_version +
                            keepalive_time +
                            flags +
                            path_vector_limit +
                            max_pdu_length +
                            lsr_id +
                            label_space_id
                          }
  let(:parameter) { LDPParameter.build_from_packet(packed_parameter) }
  let(:repacked_parameter) { parameter.pack }

  describe '.build_from_packet' do
    it 'unpacks the parameter' do
      expect(parameter.protocol_version).to eq(1)
      expect(parameter.keepalive_time).to eq(15)
      expect(parameter.flags).to eq(0) # TODO test actual booleans
      expect(parameter.path_vector_limit).to eq(0)
      expect(parameter.max_pdu_length).to eq(0)
      expect(parameter.lsr_id.to_s).to eq("10.1.1.1")
      expect(parameter.label_space_id).to eq(0)
    end
  end

  describe '#pack' do
    it 'packs the parameter' do
      expect(repacked_parameter).to eq(packed_parameter)
    end
  end
end

