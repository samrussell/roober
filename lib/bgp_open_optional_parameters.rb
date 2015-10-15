class BGPOpenOptionalParameters
  def self.build_from_packet(optional_parameters_block)
    @optional_parameters_block = optional_parameters_block
    BGPOpenOptionalParameters.new
  end
end
