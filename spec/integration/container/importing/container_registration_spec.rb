# frozen_string_literal: true

RSpec.describe "Container / Imports / Container registration" do
  let(:exporting_container) {
    Class.new(Dry::System::Container) {
      register "block_component" do
        Object.new
      end

      register "direct_component", Object.new

      register "memoized_component", memoize: true do
        Object.new
      end
    }
  }

  let(:importing_container) {
    exporting_container = self.exporting_container

    Class.new(Dry::System::Container) {
      import from: exporting_container, as: :other
    }
  }

  it "imports components with the same options as their original registration" do
    block_component_a = importing_container["other.block_component"]
    block_component_b = importing_container["other.block_component"]

    expect(block_component_a).to be_an_instance_of(block_component_b.class)
    expect(block_component_a).not_to be block_component_b

    direct_component_a = importing_container["other.direct_component"]
    direct_component_b = importing_container["other.direct_component"]

    expect(direct_component_a).to be direct_component_b

    memoized_component_a = importing_container["other.memoized_component"]
    memoized_component_b = importing_container["other.memoized_component"]

    expect(memoized_component_a).to be memoized_component_b
  end
end
