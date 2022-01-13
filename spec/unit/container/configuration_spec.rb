# frozen_string_literal: true

require "dry/system/container"

RSpec.describe Dry::System::Container, "configuration phase" do
  subject(:container) { Class.new(described_class) }

  describe "#configure" do
    it "configures the container" do
      expect {
        container.configure do |config|
          config.root = "/root"
        end
      }.to change { container.config.root }.to Pathname("/root")
    end

    it "marks the container as configured" do
      expect { container.configure {} }
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

      expect { container.configure {} }
        .to change { container.hooks_trace }
        .from([])
        .to [:after_configure]
    end

    it "does not run after configure hooks when called a second time" do
      container.instance_eval do
        def hooks_trace
          @hooks_trace ||= []
        end

        after :configure do
          hooks_trace << :after_configure
        end
      end

      expect { container.configure {}; container.configure {} }
        .to change { container.hooks_trace }
        .from([])
        .to [:after_configure]
    end

    it "finalizes (freezes) the config" do
      expect { container.configure {} }
        .to change { container.config.frozen? }
        .from(false).to true

      expect { container.configure { |c| c.root = "/root" } }
        .to raise_error Dry::Configurable::FrozenConfig
    end

    it "does not finalize the config with `finalize_config: false`" do
      expect { container.configure(finalize_config: false) {} }
        .not_to change { container.config.frozen? }

      expect(container.config).not_to be_frozen

      expect { container.configure { |c| c.root = "/root" } }
        .not_to raise_error
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

    it "finalizes (freezes) the config" do
      expect { container.configured! }
        .to change { container.config.frozen? }
        .from(false).to true

      expect { container.config.root = "/root" }.to raise_error Dry::Configurable::FrozenConfig
    end

    it "does not finalize the config with `finalize_config: false`" do
      expect { container.configured!(finalize_config: false) }
        .not_to change { container.config.frozen? }

      expect(container.config).not_to be_frozen

      expect { container.config.root = "/root" }.not_to raise_error
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
