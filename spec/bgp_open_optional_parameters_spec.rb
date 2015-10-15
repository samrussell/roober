require 'spec_helper'
require 'bgp_open_optional_parameters'

RSpec.describe BGPOpenOptionalParameters do
  # RFC5492 http://tools.ietf.org/html/rfc5492
  describe '.build_from_packet' do
    #let(:hold_time) { [180].pack('S>').force_encoding('UTF-8') }
    #let(:sender_id) { [10, 0, 0, 9].pack('CCCC').force_encoding('UTF-8') }
    let(:optional_parameters_length) { [12].pack('C').force_encoding('UTF-8') }
    let(:optional_parameters) { '' }
    let(:optional_parameters_block) {
      optional_parameters_length +
      optional_parameters
    }
    let(:raw_packet_data) { optional_parameters_block }
  end
end
