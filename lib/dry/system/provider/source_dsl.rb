require_relative "source"

module Dry
  module System
    class Provider
      class SourceDSL
        attr_reader :source_class

        def self.source_from(&block)
          dsl = new
          dsl.instance_eval(&block)
          dsl.source_class
        end

        def initialize
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
      end
    end
  end
end
