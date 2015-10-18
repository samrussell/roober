require 'spec_helper'
require 'slicer'

RSpec.describe Slicer do
  describe '#to_a' do
    let(:packed_data) { '' }
    let(:prefix_length) { 0 }
    let(:length_field_length) { 1 }
    let(:slicer) { Slicer.new(packed_data, prefix_length, length_field_length) }

    context 'slices 0 byte prefix, 1 byte length' do
      let(:prefix_length) { 0 }
      let(:length_field_length) { 1 }
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
      subject(:array) { slicer.to_a }

      it { is_expected.to eq(unpacked_data) }
    end

    context 'slices 1 byte prefix, 1 byte length' do
      let(:prefix_length) { 1 }
      let(:length_field_length) { 1 }
      let(:packed_data) {
        [31, 5, 1, 2, 3, 4, 5].pack('CCCCCCC') +
        [41, 2, 11, 12].pack('CCCC') +
        [51, 0].pack('CC') +
        [61, 8, 21, 22, 23, 24, 25, 26, 27, 28].pack('CCCCCCCCCC')
      }
      let(:unpacked_data) {
        [
          [31, 5, 1, 2, 3, 4, 5].pack('CCCCCCC'),
          [41, 2, 11, 12].pack('CCCC'),
          [51, 0].pack('CC'),
          [61, 8, 21, 22, 23, 24, 25, 26, 27, 28].pack('CCCCCCCCCC')
        ]
      }
      subject(:array) { slicer.to_a }

      it { is_expected.to eq(unpacked_data) }
    end

    context 'slices 1 byte prefix, 2 byte length' do
      let(:prefix_length) { 1 }
      let(:length_field_length) { 2 }
      let(:packed_data) {
        [31, 5, 1, 2, 3, 4, 5].pack('CS>CCCCC') +
        [41, 2, 11, 12].pack('CS>CC') +
        [51, 0].pack('CS>') +
        [61, 8, 21, 22, 23, 24, 25, 26, 27, 28].pack('CS>CCCCCCCC')
      }
      let(:unpacked_data) {
        [
          [31, 5, 1, 2, 3, 4, 5].pack('CS>CCCCC'),
          [41, 2, 11, 12].pack('CS>CC'),
          [51, 0].pack('CS>'),
          [61, 8, 21, 22, 23, 24, 25, 26, 27, 28].pack('CS>CCCCCCCC')
        ]
      }
      subject(:array) { slicer.to_a }

      it { is_expected.to eq(unpacked_data) }
    end
    #TODO spec error when not enough data to unpack
  end
end
