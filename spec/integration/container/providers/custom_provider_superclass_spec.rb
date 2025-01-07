# frozen_string_literal: true

RSpec.describe "Providers / Custom provider superclass" do
  let!(:custom_superclass) do
    module Test
      class CustomSource < Dry::System::Provider::Source
        attr_reader :custom_setting

        def initialize(custom_setting:, **options, &)
          super(**options, &)
          @custom_setting = custom_setting
        end
      end
    end

    Test::CustomSource
  end

  let!(:custom_registrar) do
    module Test
      class CustomRegistrar < Dry::System::ProviderRegistrar
        def provider_source_class = Test::CustomSource
        def provider_source_options = {custom_setting: "hello"}
      end
    end

    Test::CustomRegistrar
  end

  subject(:system) do
    module Test
      class Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/app").realpath
          config.provider_registrar = Test::CustomRegistrar
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
    expect(provider_source.custom_setting).to eq "hello"
  end

  context "Source class != provider_source_class" do
    let!(:custom_source) do
      module Test
        class OtherSource < Dry::System::Provider::Source
          attr_reader :options

          def initialize(**options, &block)
            @options = options.except(:provider_container, :target_container)
            super(**options.slice(:provider_container, :target_container), &block)
          end
        end
      end

      Test::OtherSource
    end

    specify "External source doesn't use provider_source_options" do
      Dry::System.register_provider_source(:test, group: :custom, source: custom_source)
      system.register_provider(:test, from: :custom) {}

      expect {
        provider_source = system.providers[:test].source
        expect(provider_source.class).to be < Dry::System::Provider::Source
        expect(provider_source.options).to be_empty
      }.to_not raise_error
    end

    specify "Class-based source doesn't use provider_source_options" do
      system.register_provider(:test, source: custom_source)

      expect {
        provider_source = system.providers[:test].source
        expect(provider_source.class).to be < Dry::System::Provider::Source
        expect(provider_source.options).to be_empty
      }.to_not raise_error
    end
  end
end
