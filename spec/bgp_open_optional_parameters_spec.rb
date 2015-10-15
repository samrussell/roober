require 'spec_helper'
require 'bgp_open_optional_parameters'

RSpec.describe BGPOpenOptionalParameters do
  # RFC5492 http://tools.ietf.org/html/rfc5492
  # sample data from https://www.cloudshark.org/captures/004f81c952b7
  # BGP capability code register: http://www.iana.org/assignments/capability-codes/capability-codes.xhtml
  describe '.build_from_packet' do
    #let(:hold_time) { [180].pack('S>') }
    #let(:sender_id) { [10, 0, 0, 9].pack('CCCC') }
    let(:optional_parameters_length) { [12].pack('C') }
    let(:optional_parameters) { "\x02\x06\x01\x04\x00\x01\x00\x01\x02\x02\x80\x00\x02\x02\x02\x00".force_encoding(Encoding::ASCII_8BIT) }
    let(:optional_parameters_block) {
      optional_parameters_length +
      optional_parameters
    }
    let(:raw_packet_data) { optional_parameters_block }

    context 'with valid optional parameters' do
      it 'is a BGPOpenOptionalParamters object' do
        expect(BGPOpenOptionalParameters.build_from_packet(optional_parameters_block))
          .to be_a_kind_of(BGPOpenOptionalParameters)
      end
    end
  end
end
