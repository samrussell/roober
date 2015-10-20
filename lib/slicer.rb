class Slicer
  LENGTH_FIELD_UNPACK_STRING = {
    1 => 'C',
    2 => 'S>',
    4 => 'L>'
  }

  include Enumerable

  def initialize(packed_data, prefix_length = 0, length_field_length = 1)
    @packed_data = packed_data
    @prefix_length = prefix_length
    @length_field_length = length_field_length
  end

  def each
    while item = next_item
      yield item
    end
  end

  private

  def no_more_data?
    @packed_data.nil? || @packed_data.length == 0
  end

  def next_item
    return nil if no_more_data?

    pop_first_n_bytes_of_data(slice_length)
  end

  def slice_length
    length_field_value + @length_field_length + @prefix_length
  end

  def pop_first_n_bytes_of_data(number_of_bytes)
    first_n_bytes_of_data = @packed_data.byteslice(0, number_of_bytes)

    remove_first_n_bytes_of_data(number_of_bytes)

    first_n_bytes_of_data
  end

  def remove_first_n_bytes_of_data(number_of_bytes)
    @packed_data = @packed_data.byteslice(number_of_bytes..-1)
  end

  def length_field_value
    unpack_string = LENGTH_FIELD_UNPACK_STRING[@length_field_length]

    packed_length_field = @packed_data.byteslice(@prefix_length, @length_field_length)
    
    packed_length_field.unpack(unpack_string)[0]
  end
end
