require 'spec_helper'
require 'bgp_update_nlri'

RSpec.describe BGPUpdateNLRI do
  describe '.unpack' do
    let(:packed_nlri) { "\x15\xac\x10\x00\x18\xac\x11\x00\x18\xac\x12\x00".force_encoding('ASCII-8BIT') }
    subject(:unpacked_nlri) { BGPUpdateNLRI.unpack(packed_nlri) }

    context 'with valid input' do
      it 'unpacks everything correctly' do
        expect(unpacked_nlri.size).to eq(3)
        #TODO test nlri contents
      end
    end
    #TODO test invalid input
  end
end
