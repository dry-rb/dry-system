# frozen_string_literal: true

module Dry
  module System
    class Provider
      # @api private

      # TODO: better name... RealizedEnvironment?
      class ExecEnvironment
        CALLBACK_MAP = Hash.new { |h, k| h[k] = [] }.freeze

        attr_reader :callbacks, :source_environment, :target_container

        # @api private
        def initialize(provider, source_environment, &block)
          @config = nil
          @config_block = nil

          @callbacks = {before: CALLBACK_MAP.dup, after: CALLBACK_MAP.dup}
          @source_environment = source_environment
          @target_container = provider.target_container
          # TODO: I wonder if we even want the whole provider passed here... I'm guessing no
          # TODO: I wonder if we can also do away with the target_container being passed?
          # @step_environment = step_environment

          # TODO: I wonder if this instance_exec should happen externally so we don't need
          # to worry about the target container here?
          instance_exec(target_container, &block) if block
        end

        def configure(&block)
          @config_block = block
          self
        end

        def config
          @config || configure!
        end

        private def configure!
          if source_environment.settings
            @config = source_environment.settings.new(Components::Config.new(&@config_block))
          end
        end

        def before(event, &block)
          if event.to_sym == :init
            Dry::Core::Deprecations.announce(
              "Dry::System::Provider before(:init) callback",
              "Use `before(:prepare)` callback instead",
              tag: "dry-system",
              uplevel: 1
            )

            event = :prepare
          end

          callbacks[:before][event] << block
          self
        end

        def after(event, &block)
          if event.to_sym == :init
            Dry::Core::Deprecations.announce(
              "Dry::System::Provider after(:init) callback",
              "Use `after(:prepare)` callback instead",
              tag: "dry-system",
              uplevel: 1
            )

            event = :prepare
          end

          callbacks[:after][event] << block
          self
        end

        def callbacks_for(hook, step_name)
          callbacks[hook][step_name]
        end
      end
    end
  end
end
