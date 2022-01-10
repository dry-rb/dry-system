# frozen_string_literal: true

require "dry/configurable"

module Dry
  module System
    class Provider
      class Source
        include Dry::Configurable

        # def self.name=(name)
        #   @name = name
        # end

        # def self.name
        #   @name
        # end

        attr_reader :name, :namespace

        CALLBACK_MAP = Hash.new { |h, k| h[k] = [] }.freeze
        attr_reader :callbacks

        attr_reader :provider_container
        alias_method :container, :provider_container

        attr_reader :target_container
        alias_method :target, :target_container

        def initialize(name:, namespace:, provider_container:, target_container:, &block)
          # I wonder if these are useful...
          @name = name
          @namespace = namespace

          @callbacks = {before: CALLBACK_MAP.dup, after: CALLBACK_MAP.dup}
          @provider_container = provider_container
          @target_container = target_container
          instance_exec(&block) if block
        end

        def prepare
        end

        def start
        end

        def stop
        end

        def use(*names)
          names.each do |name|
            target_container.start(name)
          end
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
            # TODO: Is it OK that these run in the same environment as the source? I think so...
            instance_eval(&callback)
          end
        end

        # def callback_for(hook, step)
        #   callbacks[hook][step]
        # end

        private

        def register(*args)
          provider_container.register(*args)
        end

        def resolve(*args)
          provider_container.resolve(*args)
        end

        def run_step_block(step_name)
          step_block = self.class.step_blocks[step_name]
          instance_eval(&step_block) if step_block
        end

        def method_missing(name, *args, &block)
          if container.key?(name)
            container[name]
          else
            super
          end
        end

        def respond_to_missing?(name, include_all = false)
          container.key?(name) || super
        end
      end
    end
  end
end
