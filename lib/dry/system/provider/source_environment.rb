# frozen_string_literal: true

require "dry/core/deprecations"
require "dry/system/settings"

module Dry
  module System
    class Provider
      class SourceEnvironment


        attr_reader :steps

        # @api private
        def initialize(provider, &source_block)
          @steps = {}

          # TODO: figure out the best way to deal with this target_container business
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
          set_or_return_step(:prepare, &block)
        end

        # @api public
        def start(&block)
          set_or_return_step(:start, &block)
        end

        # @api public
        def stop(&block)
          set_or_return_step(:stop, &block)
        end

        private

        # @api private
        def set_or_return_step(step_name, &block)
          if block
            steps[step_name] = block
            self
          else
            steps[step_name]
          end
        end
      end
    end
  end
end
