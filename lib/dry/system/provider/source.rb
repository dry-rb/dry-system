# frozen_string_literal: true

require "dry/configurable"
require "dry/core/class_attributes"
require_relative "source_dsl"

module Dry
  module System
    class Provider
      class Source
        class << self
          # Returns a new Dry::System::Provider::Source subclass with its behavior supplied by the
          # given block, which is evaluated using Dry::System::Provider::SourceDSL.
          #
          # @see Dry::System::Provider::SourceDSL
          #
          # @api private
          def for(name:, group: nil, &block)
            Class.new(self).tap { |klass|
              klass.source_name name
              klass.source_group group
              SourceDSL.evaluate(klass, &block) if block
            }
          end

          # @api private
          def name
            source = "#{source_name}"
            source = "#{source_group}->#{source}" if source_group

            "Dry::System::Provider::Source[#{source}]"
          end

          # @api private
          def to_s
            "#<#{name}>"
          end

          # @api private
          def inspect
            to_s
          end
        end

        CALLBACK_MAP = Hash.new { |h, k| h[k] = [] }.freeze

        extend Dry::Core::ClassAttributes
        include Dry::Configurable

        defines :source_name, :source_group

        # @api private
        attr_reader :callbacks

        # @api public
        attr_reader :provider_container

        # @api public
        alias_method :container, :provider_container

        # @api public
        attr_reader :target_container

        # @api public
        alias_method :target, :target_container

        # @api private
        def initialize(provider_container:, target_container:, &block)
          super()
          @callbacks = {before: CALLBACK_MAP.dup, after: CALLBACK_MAP.dup}
          @provider_container = provider_container
          @target_container = target_container
          instance_exec(&block) if block
        end

        def inspect
          ivars = instance_variables.map { |ivar| "#{ivar}=#{instance_variable_get(ivar).inspect}"}.join(" ")

          "#<#{self.class.name} #{ivars}>"
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
