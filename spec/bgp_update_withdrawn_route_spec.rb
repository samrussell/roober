require 'spec_helper'
require 'bgp_update_withdrawn_route'

RSpec.describe BGPUpdateWithdrawnRoute do
  describe '.unpack' do
    let(:route1_prefix_length) { 24 }
    let(:route1_prefix) { [10, 1, 1] }
    let(:route1_prefix_unpacked) { [10, 1, 1, 0] }
    let(:route1_packed) do
      [route1_prefix_length].pack('C') +
      route1_prefix.pack('CCC')
    end
    let(:route2_prefix_length) { 22 }
    let(:route2_prefix) { [10, 1, 8] }
    let(:route2_prefix_unpacked) { [10, 1, 8, 0] }
    let(:route2_packed) do
      [route2_prefix_length].pack('C') +
      route2_prefix.pack('CCC')
    end
    let(:route3_prefix_length) { 26 }
    let(:route3_prefix) { [10, 1, 1, 128] }
    let(:route3_prefix_unpacked) { [10, 1, 1, 128] }
    let(:route3_packed) do
      [route3_prefix_length].pack('C') +
      route3_prefix.pack('CCCC')
    end
    let(:packed_routes) do
      route1_packed + route2_packed + route3_packed
    end
    subject(:unpacked_routes) { BGPUpdateWithdrawnRoute.unpack(packed_routes) }

    context 'with valid input' do
      it 'unpacks everything correctly' do
        expect(unpacked_routes.size).to eq(3)
        expect(unpacked_routes[0].prefix_length).to eq(route1_prefix_length)
        expect(unpacked_routes[0].prefix).to eq(route1_prefix_unpacked)
        expect(unpacked_routes[1].prefix_length).to eq(route2_prefix_length)
        expect(unpacked_routes[1].prefix).to eq(route2_prefix_unpacked)
        expect(unpacked_routes[2].prefix_length).to eq(route3_prefix_length)
        expect(unpacked_routes[2].prefix).to eq(route3_prefix_unpacked)
      end
    end
    #TODO test invalid input
  end
end
