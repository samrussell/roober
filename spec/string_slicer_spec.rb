require 'spec_helper'
require 'string_slicer'

class StringSlice0BytePrefix1ByteLengthField
  def initialize(input_stream)
    @input_stream = input_stream
  end

  def call
    header = @input_stream.read(1)

    body_length = header.unpack('C').first

    body = @input_stream.read(body_length)

    header + body
  end
end

RSpec.describe StringSlicer do
  describe '#to_a' do
    let(:packed_data) { '' }
    let(:prefix_length) { 0 }
    let(:length_field_length) { 1 }
    let(:slice_klass) { nil }
    let(:slicer) { StringSlicer.new(packed_data, packed_data.length, slice_klass) }

    context 'slices 0 byte prefix, 1 byte length' do
      let(:prefix_length) { 0 }
      let(:length_field_length) { 1 }
      let(:slice_klass) { StringSlice0BytePrefix1ByteLengthField }
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
      subject(:array) { slicer.to_a.map { |slice| slice} }

      it { is_expected.to eq(unpacked_data) }
    end
    #TODO spec error when not enough data to unpack
  end
end
