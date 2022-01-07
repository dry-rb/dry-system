# frozen_string_literal: true

require "dry/system/components"

RSpec.xdescribe "Settings component" do
  subject(:system) do
    Class.new(Dry::System::Container) do
      setting :env

      configure do |config|
        config.root = SPEC_ROOT.join("fixtures").join("settings_test")
        config.env = :test
      end

      register_provider(:settings, from: :system) do
        before(:prepare) do
          require_from_root "types"
        end

        settings do
          key :database_url, SettingsTest::Types::String.constrained(filled: true)
          key :session_secret, SettingsTest::Types::String.constrained(filled: true)
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

        register_provider(:settings, from: :system) do
          before(:prepare) do
            require_from_root "types"
          end

          settings do
            key :integer_value, SettingsTest::Types::Strict::Integer
            key :coercible_value, SettingsTest::Types::Coercible::Integer
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
        Dry::System::InvalidSettingsError,
        <<~TEXT
          Could not initialize settings. The following settings were invalid:

          integer_value: "foo" violates constraints (type?(Integer, "foo") failed)
          coercible_value: invalid value for Integer(): "foo"
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

        register_provider(:settings, from: :system) do
          before(:prepare) do
            require_from_root "types"
          end

          settings do
            key :number_of_workers, SettingsTest::Types::Coercible::Integer.default(14)
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
