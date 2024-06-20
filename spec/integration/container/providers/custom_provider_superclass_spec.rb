# frozen_string_literal: true

RSpec.describe "Providers / Custom provider superclass" do
  let!(:custom_superclass) do
    module Test
      class CustomSource < Dry::System::Provider::Source
        def custom_api = :hello
      end
    end

    Test::CustomSource
  end

  subject(:system) do
    module Test
      class Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/app").realpath
          config.provider_source_class = Test::CustomSource
        end
      end
    end

    Test::Container
  end

  it "overrides the default Provider Source base class" do
    system.register_provider(:test) {}

    provider_source = system.providers[:test].source

    expect(provider_source.class).to be < custom_superclass
    expect(provider_source.class.name).to eq "Test::CustomSource[test]"
    expect(provider_source.custom_api).to eq :hello
  end
end
