class AbstractSlice
  def initialize(input_stream)
    @input_stream = input_stream
  end

  def call
    return nil unless read_initial

    read_remainder

    @initial + @remainder
  end

  protected

  def initial_length
    raise NotImplementedError
  end

  def remainder_length
    raise NotImplementedError
  end

  private

  def read_initial
    @initial = @input_stream.read(initial_length)
  end

  def read_remainder
    @remainder = @input_stream.read(remainder_length)
  end
end
