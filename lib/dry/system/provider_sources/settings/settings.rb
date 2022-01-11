# frozen_string_literal: true

require "dry/configurable"
require_relative "file_loader"

module Dry
  module System
    module ProviderSources
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

        class Settings
          include Dry::Configurable

          class << self
            def load(root, env)
              env_data = load_files(root, env)

              errors = {}

              new.tap do |settings_obj|
                settings.to_a.each do |setting_name|
                  value = ENV.fetch(setting_name.to_s.upcase) { env_data[setting_name.to_s.upcase] }

                  begin
                    settings_obj.config.send(:"#{setting_name}=", value) if value
                  rescue => e # rubocop:disable Style/RescueStandardError
                    errors[setting_name] = e
                  end
                end

                raise InvalidSettingsError, errors unless errors.empty?
              end
            end

            private

            def load_files(root, env)
              FileLoader.new.(root, env)
            end
          end
        end
      end
    end
  end
end
