# frozen_string_literal: true

require "dry/system/cycle_visualization"

RSpec.describe Dry::System::CycleVisualization do
  subject(:visualizer) { described_class.new(cycle) }
  let(:cycle) { [] }

  describe ".generate" do
    context "with empty cycle" do
      it "returns empty string" do
        expect(described_class.generate([])).to eq("")
      end
    end

    context "with single component" do
      it "generates small cycle visualization" do
        result = described_class.generate(["single"])
        expect(result).to include("single ───► single")
        expect(result).to include("▲")
        expect(result).to include("└")
      end
    end

    context "with two components" do
      it "generates bidirectional arrow" do
        result = described_class.generate(%w[foo bar])
        expect(result).to eq("foo ◄──► bar")
      end

      it "handles components with different lengths" do
        result = described_class.generate(%w[short very_long_component_name])
        expect(result).to eq("short ◄──► very_long_component_name")
      end
    end

    context "with three components" do
      it "generates small cycle visualization" do
        result = described_class.generate(%w[alpha beta gamma])

        expected = <<~CYCLE.strip
          alpha ───► beta
          beta ───► gamma
          gamma ───► alpha
          ▲           │
          └───────────┘
        CYCLE

        expect(result).to eq(expected)
      end

      it "adjusts arrow width based on component names" do
        result = described_class.generate(%w[a b c])

        expect(result).to include("a ───► b")
        expect(result).to include("b ───► c")
        expect(result).to include("c ───► a")
        expect(result).to include("▲")
        expect(result).to include("└")
      end
    end

    context "with four components" do
      it "generates small cycle visualization" do
        result = described_class.generate(%w[widget xenon yacht zorro])

        expected_lines = [
          "widget ───► xenon",
          "xenon ───► yacht",
          "yacht ───► zorro",
          "zorro ───► widget"
        ]

        expected_lines.each do |line|
          expect(result).to include(line)
        end

        expect(result).to include("▲")
        expect(result).to include("└")
      end
    end

    context "with five or more components" do
      it "generates large cycle visualization" do
        cycle = %w[apple banana cherry date elderberry]
        result = described_class.generate(cycle)

        expected_cycle_text = "apple ───► banana ───► cherry ───► date ───► elderberry ───► apple"
        expect(result).to include(expected_cycle_text)
        expect(result).to include("▲")
        expect(result).to include("└")
      end

      it "handles very long cycles" do
        cycle = %w[service_a service_b service_c service_d service_e service_f service_g]
        result = described_class.generate(cycle)

        expect(result).to include("service_a ───►")
        expect(result).to include("───► service_g ───► service_a")
        expect(result).to include("▲")
        expect(result).to include("└")
      end
    end

    context "with special characters in component names" do
      it "handles underscores and numbers" do
        result = described_class.generate(%w[component_1 component_2])
        expect(result).to eq("component_1 ◄──► component_2")
      end

      it "handles mixed case" do
        result = described_class.generate(%w[MyComponent YourComponent])
        expect(result).to eq("MyComponent ◄──► YourComponent")
      end
    end
  end

  describe "#initialize" do
    it "stores the cycle" do
      cycle = %w[foo bar]
      visualizer = described_class.new(cycle)

      expect(visualizer.instance_variable_get(:@cycle)).to eq(cycle)
    end
  end

  describe "#generate" do
    let(:cycle) { %w[test example] }

    it "delegates to class method behavior" do
      expect(visualizer.generate).to eq("test ◄──► example")
    end
  end

  describe "private methods" do
    let(:cycle) { %w[alpha beta gamma] }

    describe "#generate_bidirectional_arrow" do
      let(:cycle) { %w[left right] }

      it "creates proper bidirectional arrow" do
        result = visualizer.send(:generate_bidirectional_arrow)
        expect(result).to eq("left ◄──► right")
      end
    end

    describe "#generate_small_cycle" do
      it "creates cycle with return arrow" do
        result = visualizer.send(:generate_small_cycle)

        expect(result).to include("alpha ───► beta")
        expect(result).to include("beta ───► gamma")
        expect(result).to include("gamma ───► alpha")
        expect(result).to include("▲")
        expect(result).to include("└")
      end
    end

    describe "#generate_large_cycle" do
      let(:cycle) { %w[a b c d e f] }

      it "creates compact cycle representation" do
        result = visualizer.send(:generate_large_cycle)

        expect(result).to include("a ───► b ───► c ───► d ───► e ───► f ───► a")
        expect(result).to include("▲")
        expect(result).to include("└")
      end
    end

    describe "#build_visual_return_arrow" do
      it "creates return arrow with correct width" do
        result = visualizer.send(:build_visual_return_arrow, 10)

        lines = result.split("\n")
        expect(lines.length).to eq(2)
        expect(lines[0]).to start_with("▲")
        expect(lines[0]).to end_with("│")
        expect(lines[1]).to start_with("└")
        expect(lines[1]).to end_with("┘")

        # Check that both lines have the expected width
        expected_width = 10 + 6 + 2 # width + padding + arrow chars
        expect(lines[0].length).to eq(expected_width)
        expect(lines[1].length).to eq(expected_width)
      end

      it "handles zero width" do
        result = visualizer.send(:build_visual_return_arrow, 0)

        lines = result.split("\n")
        expect(lines[0]).to eq("▲      │")
        expect(lines[1]).to eq("└──────┘")
      end
    end
  end

  describe "edge cases" do
    context "with nil in cycle array" do
      it "handles nil values gracefully" do
        # This shouldn't happen in practice, but let's be defensive
        expect { described_class.generate([nil, "component"]) }.not_to raise_error
      end
    end

    context "with very long component names" do
      it "handles long names" do
        long_name = "a" * 100
        result = described_class.generate([long_name, "short"])

        expect(result).to include(long_name)
        expect(result).to include("short")
        expect(result).to include("◄──►")
      end
    end
  end
end
