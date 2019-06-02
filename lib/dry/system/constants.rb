# frozen_string_literal: true

require 'dry/core/constants'

module Dry
  module System
    include Dry::Core::Constants

    RB_EXT = '.rb'
    RB_GLOB = '*.rb'
    PATH_SEPARATOR = '/'
    DEFAULT_SEPARATOR = '.'
    WORD_REGEX = /\w+/.freeze

    DuplicatedComponentKeyError = Class.new(ArgumentError)
    InvalidSettingsError = Class.new(ArgumentError) do
      # @api private
      def initialize(attributes)
        message = <<~EOF
          Could not initialize settings. The following settings were invalid:

          #{attributes_errors(attributes).join("\n")}
        EOF
        super(message)
      end

      private

      def attributes_errors(attributes)
        attributes.map { |key, error| "#{key.name}: #{error}" }
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
