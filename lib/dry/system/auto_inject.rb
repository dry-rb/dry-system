# frozen_string_literal: true

require 'dry-auto_inject'

module Dry
  module System
    # @api private
    module AutoInject
      # @api private
      ForbiddenInjectionError = Class.new(StandardError)

      # Dry system specific injector builder class
      #
      # @api private
      class Builder < Dry::AutoInject::Builder
        def initialize(container, options = {})
          super
          @pattern = options.fetch(:pattern) { nil }
        end

        # @api private
        def allow(pattern)
          ::Dry::System::AutoInject::Builder.new(@container, pattern: pattern, strategies: @strategies)
        end

        # @api private
        def [](*dependency_names)
          unless match_by_pattern?(dependency_names)
            ::Kernel.raise AutoInject::ForbiddenInjectionError,
              "injecting #{dependency_names} dependencies forbidden for injector pattern #{@pattern}"
          end

          super
        end

      private

        def match_by_pattern?(dependency_names)
          @pattern.nil? || dependency_names.all? { |dependency| dependency.match(@pattern) }
        end
      end
    end
  end
end
