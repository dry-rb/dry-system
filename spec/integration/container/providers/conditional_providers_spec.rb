# frozen_string_literal: true

RSpec.describe "Providers / Conditional providers" do
  let(:container) {
    provider_if = self.provider_if
    Class.new(Dry::System::Container) {
      def self.load_the_provider?(name)
        false
      end

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

  describe "conditional on simple values" do
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

  describe "conditional on proc" do
    describe "proc returns true" do
      let(:provider_if) { proc { true } }

      context "lazy loading" do
        include_examples "loads the provider"
      end

      context "finalized" do
        before { container.finalize! }
        include_examples "loads the provider"
      end
    end

    describe "proc returns false" do
      let(:provider_if) { proc { false } }

      context "lazy loading" do
        include_examples "does not load the provider"
      end

      context "finalized" do
        before { container.finalize! }
        include_examples "does not load the provider"
      end
    end

    describe "lambda (or proc) accepting container as argument" do
      let(:provider_if) {
        lambda { |container| container.load_the_provider?(:provided) }
      }

      context "lazy loading" do
        include_examples "does not load the provider"
      end

      context "finalized" do
        before { container.finalize! }
        include_examples "does not load the provider"
      end
    end

    describe "lambda without arguments" do
      let(:provider_if) { lambda { false } }

      it "raises an argument error" do
        expect { container }.to raise_error ArgumentError, /given 1, expected 0/
      end
    end
  end
end
