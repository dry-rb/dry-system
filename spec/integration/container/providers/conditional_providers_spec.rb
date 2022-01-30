# frozen_string_literal: true

RSpec.describe "Providers / Conditional providers" do
  let(:container) {
    provider_if = self.provider_if
    Class.new(Dry::System::Container) {
      register_provider :provided, if: provider_if do
        start do
          register "provided", Object.new
        end
      end
    }
  }

  shared_examples "loads the provider" do
    it "registers the provider" do
      expect(container.providers.key?(:provided)).to be true
    end

    it "runs the provider" do
      expect(container["provided"]).to be
    end
  end

  shared_examples "does not load the provider" do
    it "does not register the provider" do
      expect(container.providers.key?(:provided)).to be false
    end

    it "does not run the provider" do
      expect { container["provided"] }.to raise_error(Dry::Container::Error, /Nothing registered/)
    end
  end

  describe "true" do
    let(:provider_if) { true }

    context "lazy loading" do
      include_examples "loads the provider"
    end

    context "finalized" do
      before { container.finalize! }
      include_examples "loads the provider"
    end
  end

  describe "false" do
    let(:provider_if) { false }

    context "lazy loading" do
      include_examples "does not load the provider"
    end

    context "finalized" do
      before { container.finalize! }
      include_examples "does not load the provider"
    end
  end
end
