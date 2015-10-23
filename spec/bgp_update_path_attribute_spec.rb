require 'spec_helper'
require 'bgp_update_path_attribute'

RSpec.describe BGPUpdatePathAttribute do
  describe '.unpack' do
    let(:packed_attributes) { "\x40\x01\x01\x02\x40\x02\x0a\x02\x01\x00\x1e\x01\x02\x00\x0a\x00\x14\x40\x03\x04\x0a\x00\x00\x09\x80\x04\x04\x00\x00\x00\x00\xc0\x07\x06\x00\x1e\x0a\x00\x00\x09".force_encoding('ASCII-8BIT') }
    subject(:unpacked_attributes) { BGPUpdatePathAttribute.unpack(packed_attributes) }

    context 'with valid input' do
      it 'unpacks everything correctly' do
        expect(unpacked_attributes.size).to eq(5)
        #expect(unpacked_routes[0].prefix_length).to eq(route1_prefix_length)
        #expect(unpacked_routes[0].prefix).to eq(route1_prefix_unpacked)
      end
    end
    #TODO test invalid input
  end
end
