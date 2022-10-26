# frozen_string_literal: true

module Dry
  module System
    class Provider
      # Configures a Dry::System::Provider::Source subclass using a DSL that makes it
      # nicer to define source behaviour via a single block.
      #
      # @see Dry::System::Container.register_provider
      #
      # @api private
      class SourceDSL
        def self.evaluate(source_class, &block)
          new(source_class).instance_eval(&block)
        end

        attr_reader :source_class

        def initialize(source_class)
          @source_class = source_class
        end

        def setting(...)
          source_class.setting(...)
        end

        def prepare(&block)
          source_class.define_method(:prepare, &block)
        end

        def start(&block)
          source_class.define_method(:start, &block)
        end

        def stop(&block)
          source_class.define_method(:stop, &block)
        end

        private

        def method_missing(name, *args, &block)
          if source_class.respond_to?(name)
            source_class.public_send(name, *args, &block)
          else
            super
          end
        end

        def respond_to_missing?(name, include_all = false)
          source_class.respond_to?(name, include_all) || super
        end
      end
    end
  end
end
