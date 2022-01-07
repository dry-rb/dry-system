# frozen_string_literal: true

module Dry
  module System
    class Provider
      # @api private
      class StepEvaluator
        # @api private
        def initialize(provider)
          @provider = provider
        end

        # @api private
        def call(*block_args, &step_block)
          instance_exec(*block_args, &step_block)
        end

        # @api public
        def container
          @provider.container
        end

        # @api public
        def config
          @provider.config
        end

        # @api public
        def register(*args, &block)
          container.register(*args, &block)
        end

        # @api public
        def resolve(*args, &block)
          container.resolve(*args, &block)
        end

        # @api public
        def use(*names)
          names.each do |name|
            @provider.target_container.start(name)
          end
        end

        # @api public
        def settings(&block)
          @provider.settings(&block)
        end

        private

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
