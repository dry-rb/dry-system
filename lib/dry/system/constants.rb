require 'dry/core/constants'

module Dry
  module System
    include Dry::Core::Constants

    RB_EXT = '.rb'.freeze
    RB_GLOB = '*.rb'.freeze
    PATH_SEPARATOR = '/'.freeze
    DEFAULT_SEPARATOR = '.'.freeze
    WORD_REGEX = /\w+/.freeze

    DuplicatedComponentKeyError = Class.new(ArgumentError)
    InvalidSettingValueError = Class.new(ArgumentError) do
      # @api private
      def initialize(attributes)
        message = <<~EOF
          Invalid setting values for:

          #{attributes_errors(attributes).join("\n")}
        EOF
        super(message)
      end

      private

      def attributes_errors(attributes)
        attributes.map { |key, error| "#{key} #{error}" }
      end
    end

    # Exception raise when a plugin dependency failed to load
    #
    # @api public
    PluginDependencyMissing = Class.new(StandardError) do
      # @api private
      def initialize(plugin, message)
        super("dry-system plugin #{plugin.inspect} failed to load its dependencies: #{message}")
      end
    end

  end
end
