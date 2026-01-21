# frozen_string_literal: true

module Dry
  module System
    # Generates ASCII art visualizations for dependency cycles
    #
    # @api private
    class CycleVisualization
      # Generates ASCII art for a dependency cycle
      #
      # @param cycle [Array<String>] Array of component names forming the cycle
      # @return [String] ASCII art representation of the cycle
      #
      # @api private
      def self.generate(cycle) = new(cycle).generate

      # @api private
      def initialize(cycle) = @cycle = cycle

      # @api private
      def generate
        return "" if cycle.empty?

        case cycle.length
        when 2
          generate_bidirectional_arrow
        when 3, 4
          generate_small_cycle
        else
          generate_large_cycle
        end
      end

      private

      attr_reader :cycle

      def generate_bidirectional_arrow
        "#{cycle[0]} ◄──► #{cycle[1]}"
      end

      def generate_small_cycle
        components = cycle + [cycle[0]] # Complete the cycle
        cycle_lines = components.each_cons(2).map { |a, b| "#{a} ───► #{b}" }

        cycle_text = cycle_lines.join("\n")
        visual_return_arrow = build_visual_return_arrow(components[-2].length)

        "#{cycle_text}\n#{visual_return_arrow}"
      end

      def generate_large_cycle
        cycle_text = cycle.join(" ───► ")
        cycle_text += " ───► #{cycle[0]}"

        visual_return_arrow = build_visual_return_arrow(cycle_text.length - cycle[0].length - 8)

        "#{cycle_text}\n#{visual_return_arrow}"
      end

      def build_visual_return_arrow(width)
        arrow_up = "▲#{" " * (width + 6)}│"
        arrow_line = "└#{"─" * (width + 6)}┘"

        "#{arrow_up}\n#{arrow_line}"
      end
    end
  end
end
