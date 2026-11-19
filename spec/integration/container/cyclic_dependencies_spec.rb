# frozen_string_literal: true

require "dry/system/container"

RSpec.describe "Cyclic dependency detection" do
  let(:container) { Test::Container }

  before do
    class Test::Container < Dry::System::Container
      configure do |config|
        config.root = SPEC_ROOT.join("fixtures/cyclic_components").realpath
        config.component_dirs.add "lib"
      end
    end
  end

  context "with existing cyclic fixtures" do
    it "detects the cycle and raises CyclicDependencyError" do
      expect { container["cycle_foo"] }.to raise_error(Dry::System::CyclicDependencyError) do |error|
        expect(error.message).to include("These dependencies form a cycle:")
        expect(error.message).to include("You must break this cycle")
      end
    end
  end

  context "when there are no cycles" do
    it "loads components normally without error" do
      expect { container["safe_component"] }.not_to raise_error
      expect(container["safe_component"]).to be_a(SafeComponent)
    end
  end
end
