require 'inflecto'

module Dry
  module System
    class Loader
      attr_reader :path

      def initialize(path)
        @path = path
      end

      def call(*args)
        if constant.respond_to?(:instance) && !constant.respond_to?(:new)
          constant.instance(*args) # a singleton
        else
          constant.new(*args)
        end
      end

      def constant
        Inflecto.constantize(Inflecto.classify(path))
      end
    end
  end
end
