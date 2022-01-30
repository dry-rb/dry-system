# frozen_string_literal: true

RSpec.describe "Providers / Conditional providers" do
  describe "conditional on simple values" do
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

    describe "true" do
      let(:provider_if) { true }

      context "lazy loading" do
        it "registers the provider" do
          expect(container.providers.key?(:provided)).to be true
        end

        it "runs the provider" do
          expect(container["provided"]).to be
        end
      end

      context "finalized" do
        before { container.finalize! }

        it "registers the provider" do
          expect(container.providers.key?(:provided)).to be true
        end

        it "runs the provider" do
          expect(container["provided"]).to be
        end
      end
    end

    describe "false" do
      let(:provider_if) { false }

      context "lazy loading" do
        it "does not register the provider" do
          expect(container.providers.key?(:provided)).to be false
        end

        it "does not run the provider" do
          expect { container["provided"] }.to raise_error(Dry::Container::Error, /Nothing registered/)
        end
      end

      context "finalized" do
        before { container.finalize! }

        it "does not register the provider" do
          expect(container.providers.key?(:provided)).to be false
        end

        it "does not register the provider" do
          expect { container["provided"] }.to raise_error(Dry::Container::Error, /Nothing registered/)
        end
      end
    end
  end
end
