# frozen_string_literal: true

require "dry/system/container"

RSpec.describe Dry::System::Container, "configuration phase" do
  subject(:container) { Class.new(described_class) }

  describe "#configure!" do
    it "configures the container" do
      expect {
        container.configure! do |config|
          config.root = "/root"
        end
      }.to change { container.config.root }.to Pathname("/root")
    end

    it "marks the container as configured" do
      expect { container.configure! {} }
        .to change { container.configured? }
        .from(false).to true
    end

    it "runs after configure hooks" do
      container.instance_eval do
        def hooks_trace
          @hooks_trace ||= []
        end

        after :configure do
          hooks_trace << :after_configure
        end
      end

      expect { container.configure! {} }
        .to change { container.hooks_trace }
        .from([])
        .to [:after_configure]
    end

    it "raises an error when run a second time" do
      container.configure! {}
      expect { container.configure! {} }.to raise_error(Dry::System::ContainerAlreadyConfiguredError)
    end
  end

  describe "#configured!" do
    it "marks the container as configured" do
      expect { container.configured! }
        .to change { container.configured? }
        .from(false).to true
    end

    it "runs after configure hooks" do
      container.instance_eval do
        def hooks_trace
          @hooks_trace ||= []
        end

        after :configure do
          hooks_trace << :after_configure
        end
      end

      expect { container.configured! }
        .to change { container.hooks_trace }
        .from([])
        .to [:after_configure]
    end

    it "does not run after configure hooks when run a second time" do
      container.instance_eval do
        def hooks_trace
          @hooks_trace ||= []
        end

        after :configure do
          hooks_trace << :after_configure
        end
      end

      expect { container.configured!; container.configured! }
        .to change { container.hooks_trace }
        .from([])
        .to [:after_configure]
    end

    it "finalizes the config" do
      expect { container.configured! }
        .to change { container.config.frozen? }
        .from(false).to true

      expect { container.configure { |c| c.root = "/root" } }.to raise_error FrozenError
    end
  end

  describe "#finalize!" do
    it "marks the container as configured if not configured prior" do
      expect { container.finalize! }
        .to change { container.configured? }.from(false).to true
    end

    it "runs after configure hooks if not run prior" do
      container.instance_eval do
        def hooks_trace
          @hooks_trace ||= []
        end

        after :configure do
          hooks_trace << :after_configure
        end
      end

      expect { container.finalize! }
        .to change { container.hooks_trace }
        .from([])
        .to [:after_configure]
    end

    it "does not run after configure hooks when run a second time" do
      container.instance_eval do
        def hooks_trace
          @hooks_trace ||= []
        end

        after :configure do
          hooks_trace << :after_configure
        end
      end

      expect { container.finalize!; container.finalize! }
        .to change { container.hooks_trace }
        .from([])
        .to [:after_configure]
    end
  end
end
