# frozen_string_literal: true

require_relative "cycle_bar"

class CycleFoo
  def initialize
    # This creates the cycle: CycleFoo -> CycleBar -> CycleFoo
    CycleBar.new
  end
end
