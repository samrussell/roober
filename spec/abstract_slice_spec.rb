require 'spec_helper'
require './lib/abstract_slice'

require 'stringio'

describe AbstractSlice do
  let(:initial) { "\x01\x02\x03\x04\x00\x20".force_encoding('ASCII-8BIT') }
  let(:remainder) { "\x05\x06\x07\x08".force_encoding('ASCII-8BIT') }
  let(:input_stream) { StringIO.new(initial + remainder) }
  let(:abstract_slice) { AbstractSlice.new(input_stream) }

  it 'grabs a slice from the stream' do
    expect(abstract_slice).to receive(:initial_length).and_return(6)
    expect(abstract_slice).to receive(:remainder_length).and_return(4)

    expect(abstract_slice.call).to eq(initial+remainder)
  end
end
