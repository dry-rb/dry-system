# frozen_string_literal: true

require "dry/system/container"

RSpec.describe Dry::System::Container, "configuration" do
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
        .to change { container.configured? }.from(false).to true
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

    it "finalizes (freezes) the config when flagged" do
      expect { container.configure(finalize_config: true) {} }
        .to change { container.config.frozen? }
        .from(false).to true
    end
  end
end

