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
      it 'is an array of BGPOpenOptionalParameter' do
        expect(BGPOpenOptionalParameter.build_from_packet(optional_parameters_block))
          .to contain_exactly(
            a_kind_of(BGPOpenOptionalParameter),
            a_kind_of(BGPOpenOptionalParameter),
            a_kind_of(BGPOpenOptionalParameter)
          )
      end
    end
  end
end
