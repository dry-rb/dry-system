require 'dry-configurable'

module Test
  module Bacon
    class Router
      extend Dry::Configurable

      setting :locale

      def initialize
        @routes = {}
      end

      def add_route(path, response)
        @routes[path] = response
      end

      def route(path)
        @routes[path]
      end
    end
  end
end
