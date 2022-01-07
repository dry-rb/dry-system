# frozen_string_literal: true

require "dry/core/deprecations"
require "dry/system/settings"

module Dry
  module System
    class Provider
      # Lifecycle booting DSL
      #
      # Lifecycle objects are used in the boot files where you can register custom
      # prepare/start/stop triggers
      #
      # @see [Container.register_provider]
      #
      # @api private
      class SourceDefinition
        extend ::Dry::Core::Deprecations["Dry::System::Lifecycle"]

        attr_reader :steps

        # @api private
        def initialize(provider, &source_block)
          @steps = {}
          instance_exec(provider.target_container, &source_block)
        end

        # @api private
        def call(*steps)
          steps.each do |step|
            __send__(step)
          end
        end

        # Define configuration settings with keys and types
        #
        # @api public
        def settings(&block)
          if block
            @settings_block = block
          elsif @settings_block
            @settings = Settings::DSL.new(&@settings_block).call
          else
            @settings
          end
        end

        # @api public
        def prepare(&block)
          step(:prepare, &block)
        end
        deprecate :init, :prepare

        # @api public
        def start(&block)
          step(:start, &block)
        end

        # @api public
        def stop(&block)
          step(:stop, &block)
        end

        private

        # @api private
        def step(name, &block)
          if block
            steps[name] = block
            self
          else
            steps[name]
          end
        end
      end
    end
  end
end
