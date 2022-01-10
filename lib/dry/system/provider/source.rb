# frozen_string_literal: true

require "dry/configurable"

module Dry
  module System
    class Provider
      class Source
        include Dry::Configurable

        CALLBACK_MAP = Hash.new { |h, k| h[k] = [] }.freeze
        attr_reader :callbacks

        attr_reader :container

        attr_reader :target_container

        def initialize(container:, target_container:, &block)
          @callbacks = {before: CALLBACK_MAP.dup, after: CALLBACK_MAP.dup}
          instance_exec(&block) if block
        end

        def prepare
        end

        def start
        end

        def stop
        end

        def before(step, &block)
          if step.to_sym == :init
            Dry::Core::Deprecations.announce(
              "Dry::System::Provider before(:init) callback",
              "Use `before(:prepare)` callback instead",
              tag: "dry-system",
              uplevel: 1
            )

            step = :prepare
          end

          callbacks[:before][step] << block
          self
        end

        def after(step, &block)
          if step.to_sym == :init
            Dry::Core::Deprecations.announce(
              "Dry::System::Provider after(:init) callback",
              "Use `after(:prepare)` callback instead",
              tag: "dry-system",
              uplevel: 1
            )

            step = :prepare
          end

          callbacks[:after][step] << block
          self
        end

        def run_callback(hook, step)
          callbacks[hook][step].each do |callback|
            # TODO: Is it OK that these run in the same environment as the source?
            instance_eval(&callback)
          end
        end

        # def callback_for(hook, step)
        #   callbacks[hook][step]
        # end

        private

        def register(*args)
          container.register(*args)
        end

        def resolve(*args)
          container.resolve(*args)
        end
      end
    end
  end
end
