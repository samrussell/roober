require 'spec_helper'
require 'slicer'

class Slice0BytePrefix1ByteLengthField
  attr_reader :packed_data

  def initialize(packet)
    slice_length = packet.byteslice(0).unpack('C')[0] + 1

    @packed_data = packet.byteslice(0, slice_length)
  end
end

RSpec.describe Slicer do
  describe '#to_a' do
    let(:packed_data) { '' }
    let(:prefix_length) { 0 }
    let(:length_field_length) { 1 }
    let(:slice_klass) { nil }
    let(:slicer) { Slicer.new(packed_data, slice_klass) }

    context 'slices 0 byte prefix, 1 byte length' do
      let(:prefix_length) { 0 }
      let(:length_field_length) { 1 }
      let(:slice_klass) { Slice0BytePrefix1ByteLengthField }
      let(:packed_data) {
        [5, 1, 2, 3, 4, 5].pack('CCCCCC') +
        [2, 11, 12].pack('CCC') +
        [0].pack('C') +
        [8, 21, 22, 23, 24, 25, 26, 27, 28].pack('CCCCCCCCC')
      }
      let(:unpacked_data) {
        [
          [5, 1, 2, 3, 4, 5].pack('CCCCCC'),
          [2, 11, 12].pack('CCC'),
          [0].pack('C'),
          [8, 21, 22, 23, 24, 25, 26, 27, 28].pack('CCCCCCCCC')
        ]
      }
      subject(:array) { slicer.to_a.map { |slice| slice.packed_data } }

      it { is_expected.to eq(unpacked_data) }
    end
    #TODO spec error when not enough data to unpack
  end
end
