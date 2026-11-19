# frozen_string_literal: true

require_relative "cycle_foo"

class CycleBar
  def initialize
    # This creates the cycle: CycleBar -> CycleFoo -> CycleBar
    CycleFoo.new
  end
end
