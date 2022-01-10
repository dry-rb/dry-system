require_relative "source"

module Dry
  module System
    class Provider
      class SourceBuilder
        attr_reader :source_class

        def self.source_class(name:, group: nil, &block)
          dsl = new
          # TODO: Find some nicer way to "name" the class
          dsl.source_class.name = name
          dsl.source_class.group = group
          dsl.instance_eval(&block)
          dsl.source_class
        end

        def initialize
          # TODO: should I use dry::core::classbuilder here?
          @source_class = Class.new(Source)
        end

        def setting(*args, **kwargs, &block)
          source_class.setting(*args, **kwargs, &block)
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
