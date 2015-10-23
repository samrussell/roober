class Slicer
  include Enumerable

  # need to pass a class
  # it can take a string of unknown length in its self.build_from_packet
  # it also needs to respond to packed_data and maybe packed_length
  def initialize(packed_data, slice_klass)
    @packed_data = packed_data
    @slice_klass = slice_klass
  end

  def each
    while slice = next_slice
      truncate_packet

      yield slice
    end
  end

  private

  def next_slice
    return nil if no_more_data?

    @slice = @slice_klass.new(@packed_data)
  end

  def no_more_data?
    @packed_data.nil? || @packed_data.length == 0
  end

  def slice_length
    @slice.packed_data.length
  end

  def truncate_packet
    remove_first_n_bytes_of_data(slice_length)
  end

  def remove_first_n_bytes_of_data(number_of_bytes)
    @packed_data = @packed_data.byteslice(number_of_bytes..-1)
  end
end
