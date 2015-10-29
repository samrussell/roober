class IOSlicer
  include Enumerable

  # need to pass a class
  # it can take a string of unknown length in its self.build_from_packet
  # it also needs to respond to packed_data and maybe packed_length
  def initialize(input_stream, input_length, slice_klass)
    @input_stream = input_stream
    @input_length = input_length
    @slice_klass = slice_klass

    @bytes_read = 0
  end

  def each
    while slice = next_slice
      @bytes_read += slice.length

      yield slice
    end
  end

  private

  def next_slice
    return nil if no_more_data?

    @slice_klass.new(@input_stream).call
  end

  def no_more_data?
    raise StandardError, "Slice took too many bytes!" if @bytes_read > @input_length

    @bytes_read == @input_length
  end
end
