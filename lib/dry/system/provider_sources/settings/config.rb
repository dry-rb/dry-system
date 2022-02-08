# frozen_string_literal: true

require "dry/configurable"
require "dry/core/deprecations"
require_relative "loader"

module Dry
  module System
    module ProviderSources
      # @api private
      module Settings
        InvalidSettingsError = Class.new(ArgumentError) do
          # @api private
          def initialize(errors)
            message = <<~STR
              Could not load settings. The following settings were invalid:

              #{setting_errors(errors).join("\n")}
            STR

            super(message)
          end

          private

          def setting_errors(errors)
            errors.sort_by { |k, _| k }.map { |key, error| "#{key}: #{error}" }
          end
        end

        # @api private
        class Config
          # @api private
          def self.load(root:, env:, loader: Loader)
            loader = loader.new(root: root, env: env)

            new.tap do |settings_obj|
              errors = {}

              settings.to_a.each do |setting_name|
                value = loader[setting_name.to_s.upcase]

                begin
                  settings_obj.config.public_send(:"#{setting_name}=", value) if value
                rescue => e # rubocop:disable Style/RescueStandardError
                  errors[setting_name] = e
                end
              end

              raise InvalidSettingsError, errors unless errors.empty?
            end
          end

          # rubocop:disable Layout/LineLength
          def self.key(name, type)
            Dry::Core::Deprecations.announce(
              "Dry::System :settings provider source setting definition using `key`",
              "Use `setting` instead, with dry-configurable `setting` options, e.g. `setting :my_setting, default: \"hello\", constructor: Types::String.constrained(min_length: 3)`",
              tag: "dry-system",
              uplevel: 1
            )

            setting(name, constructor: type)
          end
          # rubocop:enable Layout/LineLength

          include Dry::Configurable

          private

          def method_missing(name, *args, &block)
            if config.respond_to?(name)
              config.public_send(name, *args, &block)
            else
              super
            end
          end

          def respond_to_missing?(name, include_all = false)
            config.respond_to?(name, include_all) || super
          end
        end
      end
    end
  end
end
