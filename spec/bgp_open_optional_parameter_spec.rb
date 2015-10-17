require 'spec_helper'
require 'bgp_open_optional_parameter'

RSpec.describe BGPOpenOptionalParameter do
  # RFC5492 http://tools.ietf.org/html/rfc5492
  # sample data from https://www.cloudshark.org/captures/004f81c952b7
  # BGP capability code register: http://www.iana.org/assignments/capability-codes/capability-codes.xhtml
  describe '.build_from_packet' do
    let(:optional_parameter1_type) { [2].pack('C') }
    let(:optional_parameter1_length) { [6].pack('C') }
    let(:optional_parameter1_data) { [1, 4, 0, 1, 0, 1].pack('CCCCCC') }
    let(:optional_parameter1) { 
      optional_parameter1_type +
      optional_parameter1_length +
      optional_parameter1_data
    }
    let(:optional_parameter2_type) { [2].pack('C') }
    let(:optional_parameter2_length) { [2].pack('C') }
    let(:optional_parameter2_data) { [128, 0].pack('CC') }
    let(:optional_parameter2) { 
      optional_parameter2_type +
      optional_parameter2_length +
      optional_parameter2_data
    }
    let(:optional_parameter3_type) { [2].pack('C') }
    let(:optional_parameter3_length) { [2].pack('C') }
    let(:optional_parameter3_data) { [2, 0].pack('CC') }
    let(:optional_parameter3) { 
      optional_parameter3_type +
      optional_parameter3_length +
      optional_parameter3_data
    }
    let(:optional_parameters_block) {
      optional_parameter1 +
      optional_parameter2 +
      optional_parameter3
    }
    let(:raw_packet_data) { optional_parameters_block }

    context 'with valid optional parameters' do
      subject(:parameters) { BGPOpenOptionalParameter.build_from_packet(optional_parameters_block) }

      it 'is size 3' do
        expect(parameters.size).to eq(3)
      end

      context 'parameter 1' do
        subject(:parameter1) { parameters[0] }

        it 'is code 2 has data of length 6' do
          expect(parameter1.code).to eq(2)
          expect(parameter1.data.length).to eq(6)
        end
      end

      context 'parameter 2' do
        subject(:parameter2) { parameters[1] }

        it 'is code 2 has data of length 2' do
          expect(parameter2.code).to eq(2)
          expect(parameter2.data.length).to eq(2)
        end
      end

      context 'parameter 3' do
        subject(:parameter3) { parameters[2] }

        it 'is code 2 has data of length 2' do
          expect(parameter3.code).to eq(2)
          expect(parameter3.data.length).to eq(2)
        end
      end
    end
  end
end
