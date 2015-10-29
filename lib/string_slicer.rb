require 'stringio'
require './lib/io_slicer'

class StringSlicer
  include Enumerable

  def initialize(input_string, input_length, slice_klass)
    input_stream = StringIO.new(input_string)
    @io_slicer = IOSlicer.new(input_stream, input_length, slice_klass)
  end

  def each(&block)
    @io_slicer.each(&block)
  end
end
