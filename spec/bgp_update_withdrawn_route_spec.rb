require 'spec_helper'
require 'bgp_update_withdrawn_route'

RSpec.describe BGPUpdateWithdrawnRoute do
  describe '.unpack' do
    let(:route1_prefix_length) { 24 }
    let(:route1_prefix) { [10, 1, 1] }
    let(:route1_packed) do
      [route1_prefix_length].pack('C') +
      route1_prefix.pack('CCC')
    end
    let(:packed_routes) do
      route1_packed
    end
    subject(:unpacked_routes) { BGPUpdateWithdrawnRoute.unpack(packed_routes) }

    context 'with valid input' do
      it 'unpacks everything correctly' do
        expect(unpacked_routes.size).to eq(1)
        expect(unpacked_routes[0].prefix_length).to eq(route1_prefix_length)
        #TODO test for prefix
      end
    end
    #TODO test invalid input
  end
end
