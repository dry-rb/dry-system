require 'inflecto'

module Dry
  module System
    class Loader
      attr_reader :path

      def initialize(path)
        @path = path
      end

      def call(*args)
        if singleton?(constant)
          constant.instance(*args)
        else
          constant.new(*args)
        end
      end

      def constant
        Inflecto.constantize(Inflecto.camelize(path))
      end

      private

      def singleton?(constant)
        constant.respond_to?(:instance) && !constant.respond_to?(:new)
      end
    end
  end
end
