# frozen_string_literal: true

require "dry/system/provider_sources"

RSpec.describe "Settings component" do
  subject(:system) do
    Class.new(Dry::System::Container) do
      setting :env

      configure do |config|
        config.root = SPEC_ROOT.join("fixtures").join("settings_test")
        config.env = :test
      end

      register_provider(:settings, from: :dry_system) do
        before(:prepare) do
          target_container.require_from_root "types"
        end

        settings do
          setting :database_url, constructor: SettingsTest::Types::String.constrained(filled: true)
          setting :session_secret, constructor: SettingsTest::Types::String.constrained(filled: true)
        end
      end
    end
  end

  let(:settings) do
    system[:settings]
  end

  before do
    ENV["DATABASE_URL"] = "sqlite::memory"
  end

  after do
    ENV.delete("DATABASE_URL")
  end

  it "sets up system settings component via ENV and .env" do
    expect(settings.database_url).to eql("sqlite::memory")
    expect(settings.session_secret).to eql("super-secret")
  end

  context "Invalid setting value" do
    subject(:system) do
      Class.new(Dry::System::Container) do
        setting :env

        configure do |config|
          config.root = SPEC_ROOT.join("fixtures").join("settings_test")
          config.env = :test
        end

        register_provider(:settings, from: :dry_system) do
          before(:prepare) do
            target_container.require_from_root "types"
          end

          settings do
            setting :integer_value, constructor: SettingsTest::Types::Integer
            setting :coercible_value, constructor: SettingsTest::Types::Coercible::Integer
          end
        end
      end
    end

    before do
      ENV["INTEGER_VALUE"] = "foo"
      ENV["COERCIBLE_VALUE"] = "foo"
    end

    after do
      ENV.delete("INTEGER_VALUE")
      ENV.delete("COERCIBLE_VALUE")
    end

    it "raises InvalidSettingsError with meaningful message" do
      expect {
        settings.integer_value
      }.to raise_error(
        Dry::System::ProviderSources::Settings::InvalidSettingsError,
        <<~TEXT
          Could not load settings. The following settings were invalid:

          coercible_value: invalid value for Integer(): "foo"
          integer_value: "foo" violates constraints (type?(Integer, "foo") failed)
        TEXT
      )
    end
  end

  context "With default values" do
    subject(:system) do
      Class.new(Dry::System::Container) do
        setting :env

        configure do |config|
          config.root = SPEC_ROOT.join("fixtures").join("settings_test")
          config.env = :test
        end

        register_provider(:settings, from: :dry_system) do
          after(:prepare) do
            target_container.require_from_root "types"
          end

          settings do
            setting :number_of_workers, default: 14, constructor: SettingsTest::Types::Coercible::Integer
          end
        end
      end
    end

    it "uses the default value" do
      expect(settings.number_of_workers).to eql(14)
    end

    context "ENV variables take precedence before defaults" do
      before do
        ENV["NUMBER_OF_WORKERS"] = "4"
      end

      after do
        ENV.delete("NUMBER_OF_WORKERS")
      end

      it "uses the ENV value" do
        expect(settings.number_of_workers).to eql(4)
      end
    end
  end
end
