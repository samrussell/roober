require 'spec_helper'
require 'ldp_parameter'
require 'stringio'
require 'string_slicer'
require 'json'

# TODO shared examples for TLV subclasses

RSpec.describe LDPParameterFEC do
  # TODO proper packet
  let(:code) { [0x0401].pack("S>") }
  let(:length) { [4].pack("S>") }
  let(:address) { [10, 1, 1, 1].pack("CCCC") }
  #let(:packed_parameter) { code + length + address }
  let(:packed_parameter) { "\x01\x00\x00\x08\x02\x00\x01\x1e\x0a\x0a\x0a\x00".force_encoding('ASCII-8BIT') }
  let(:parameter) { LDPParameter.build_from_packet(packed_parameter) }
  let(:repacked_parameter) { parameter.pack }

  describe '.build_from_packet' do
    it 'unpacks the parameter' do
      expect(parameter.prefixes.count).to eq(1)
      expect(parameter.prefixes.first.address).to eq(IPAddr.new("10.10.10.0/30"))
      expect(parameter.prefixes.first.mask).to eq(30)
    end
  end

  describe '#pack' do
    it 'packs the parameter' do
      expect(repacked_parameter).to eq(packed_parameter)
    end
  end
end

RSpec.describe LDPParameterLabel do
  # TODO proper packet
  let(:packed_parameter) { "\x02\x00\x00\x04\x00\x00\x00\x03".force_encoding('ASCII-8BIT') }
  let(:parameter) { LDPParameter.build_from_packet(packed_parameter) }
  let(:repacked_parameter) { parameter.pack }

  describe '.build_from_packet' do
    it 'unpacks the parameter' do
      expect(parameter.label).to eq(3)
    end
  end

  describe '#pack' do
    it 'packs the parameter' do
      expect(repacked_parameter).to eq(packed_parameter)
    end
  end
end

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

RSpec.describe LDPParameterAddressList do
  let(:code) { [0x0101].pack("S>") }
  let(:length) { [2 + 4 + 4 + 4].pack("S>") }
  let(:family) { [1].pack("S>") }
  let(:address1) { [10, 1, 1, 1].pack("CCCC") }
  let(:address2) { [192, 168, 2, 25].pack("CCCC") }
  let(:address3) { [8, 8, 4, 4].pack("CCCC") }
  let(:addresses) { address1 + address2 + address3 }
  let(:packed_parameter) { code + length + family + addresses }
  let(:parameter) { LDPParameter.build_from_packet(packed_parameter) }
  let(:repacked_parameter) { parameter.pack }

  describe '.build_from_packet' do
    it 'unpacks the parameter' do
      expect(parameter.addresses.map(&:to_s)).to eq(
        [
          "10.1.1.1",
          "192.168.2.25",
          "8.8.4.4"
        ]
      )
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

