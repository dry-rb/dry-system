# frozen_string_literal: true

RSpec.describe "External Components" do
  before do
    Object.send(:remove_const, :ExternalComponents) if defined? ExternalComponents
  end
  subject(:container) do
    module Test
      class Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/app").realpath
        end

        register_provider(:logger, from: :external_components)

        register_provider(:my_logger, from: :external_components, source: :logger) do
          configure do |config|
            config.log_level = :debug
          end

          after(:start) do
            register(:my_logger, container[:logger])
          end
        end

        register_provider(:notifier, from: :external_components)

        register_provider(:mailer, from: :external_components)

        register(:monitor, "a monitor")
      end
    end

    Test::Container
  end

  before do
    require SPEC_ROOT.join("fixtures/external_components/lib/external_components")
  end

  context "with default behavior" do
    it "boots external logger component" do
      container.finalize!

      expect(container[:logger]).to be_instance_of(ExternalComponents::Logger)
    end

    it "boots external logger component with customized booting process" do
      container.finalize!

      my_logger = container[:my_logger]

      expect(my_logger).to be_instance_of(ExternalComponents::Logger)
      expect(my_logger.log_level).to eq(:debug)
    end

    it "boots external notifier component which needs a local component" do
      container.finalize!

      notifier = container[:notifier]

      expect(notifier.monitor).to be(container[:monitor])
    end

    it "boots external mailer component which needs a local bootable component" do
      container.finalize!

      mailer = container[:mailer]

      expect(mailer.client).to be(container[:client])
    end
  end

  context "with customized booting" do
    it "allows aliasing external components" do
      container.register_provider(:error_logger, from: :external_components, source: :logger) do
        after(:start) do
          register(:error_logger, container[:logger])
        end
      end

      container.finalize!

      expect(container[:error_logger]).to be_instance_of(ExternalComponents::Logger)
    end

    it "allows calling :prepare manually" do
      container.register_provider(:error_logger, from: :external_components, source: :logger) do
        after(:prepare) do
          ExternalComponents::Logger.default_level = :error
        end

        after(:start) do
          register(:error_logger, container[:logger])
        end
      end

      container.prepare(:error_logger)

      expect(container[:error_logger]).to be_instance_of(ExternalComponents::Logger)
      expect(container[:error_logger].class.default_level).to be(:error)
    end
  end

  context "customized registration from an alternative provider" do
    subject(:container) do
      Class.new(Dry::System::Container) do
        register_provider(:logger, from: :external_components)

        register_provider(:conn, from: :alt, source: :db) do
          after(:start) do
            register(:conn, container[:db_conn])
          end
        end
      end
    end

    before do
      require SPEC_ROOT.join("fixtures/external_components/lib/external_components")
    end

    context "with default behavior" do
      it "boots external logger component from the specified provider" do
        container.finalize!

        expect(container[:logger]).to be_instance_of(ExternalComponents::Logger)
        expect(container[:conn]).to be_instance_of(AltComponents::DbConn)
      end

      it "lazy-boots external logger components" do
        expect(container[:logger]).to be_instance_of(ExternalComponents::Logger)
      end
    end
  end

  it "raises an error when specifying an unknown provider sourse" do
    msgs = [
      "Provider source not found: :logger, group: :not_found_components",
      "Available provider sources:",
      "- :logger, group: :external_components"
    ]
    error_re = /#{msgs.join('.*')}/m

    expect {
      Class.new(Dry::System::Container) {
        register_provider(:logger, from: :not_found_components)
      }
    }.to raise_error Dry::System::ProviderSourceNotFoundError, error_re
  end
end
