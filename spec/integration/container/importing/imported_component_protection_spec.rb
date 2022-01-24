# frozen_string_literal: true

RSpec.describe "Container / Imports / Protection of imported components from export" do
  let(:source_container_1) {
    Class.new(Dry::System::Container) {
      register("component", Object.new)
    }
  }

  let(:source_container_2) {
    container_1 = source_container_1

    Class.new(Dry::System::Container) {
      register("component", Object.new)

      import from: container_1, as: :container_1
    }
  }

  let(:importing_container) {
    container_2 = source_container_2

    Class.new(Dry::System::Container) {
      import from: container_2, as: :container_2
    }
  }

  describe "no exports configured" do
    context "importing container lazy loading" do
      it "does not import components that were themselves imported" do
        expect(importing_container.key?("container_2.component")).to be true
        expect(importing_container.key?("container_2.container_1.component")).to be false
      end
    end

    context "importing container finalized" do
      before do
        importing_container.finalize!
      end

      it "does not import components that were themselves imported" do
        expect(importing_container.keys).to eq ["container_2.component"]
      end
    end
  end

  describe "exports configured with imported components included" do
    let(:source_container_2) {
      container_1 = source_container_1

      Class.new(Dry::System::Container) {
        configure do |config|
          config.exports = %w[component container_1.component]
        end

        register("component", Object.new)

        import from: container_1, as: :container_1
      }
    }

    context "importing container lazy loading" do
      it "imports the previously-imported component" do
        expect(importing_container.key?("container_2.component")).to be true
        expect(importing_container.key?("container_2.container_1.component")).to be true
      end
    end

    context "importing container finalized" do
      before do
        importing_container.finalize!
      end

      it "imports the previously-imported component" do
        expect(importing_container.keys).to eq %w[container_2.component container_2.container_1.component]
      end
    end
  end
end
