# frozen_string_literal: true

RSpec.describe Dry::System::Provider::Source do
  let(:target_container) do
    Dry::Container.new
  end

  let(:provider_container) do
    Dry::Container.new
  end

  shared_examples_for "a provider class" do
    let(:provider) do
      provider_class.new(
        provider_container: provider_container, target_container: target_container
      )
    end

    it "exposes start callback" do
      expect(provider.provider_container.key?("persistence")).to be(false)

      provider.start

      expect(provider.provider_container.key?("persistence")).to be(true)
    end
  end

  context "using a base class" do
    it_behaves_like "a provider class" do
      let(:provider_class) do
        described_class.for(name: "Persistence") do
          start do
            register(:persistence, {})
          end
        end
      end
    end
  end

  context "using a sub-class" do
    it_behaves_like "a provider class" do
      let(:parent_class) do
        described_class.for(name: "Persistence") do
          start do
            register(:persistence, {})
          end
        end
      end

      let(:provider_class) do
        Class.new(parent_class)
      end
    end
  end
end
