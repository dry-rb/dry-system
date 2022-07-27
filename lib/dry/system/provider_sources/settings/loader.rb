# frozen_string_literal: true

module Dry
  module System
    module ProviderSources
      module Settings
        # @api private
        class Loader
          # @api private
          attr_reader :store

          # @api private
          def initialize(root:, env:, store: ENV)
            @store = store
            load_dotenv(root, env.to_sym)
          end

          # @api private
          def [](key)
            store[key]
          end

          private

          def load_dotenv(root, env)
            require "dotenv"
            Dotenv.load(*dotenv_files(root, env)) if defined?(Dotenv)
          rescue LoadError
            Dry::Core::Deprecations.announce(
              "Dry::System :settings provider now requires dotenv to to load settings from .env files`", # rubocop:disable Layout/LineLength
              "Add `gem \"dotenv\"` to your application's `Gemfile`",
              tag: "dry-system",
              uplevel: 3
            )
            # Do nothing if dotenv is unavailable
          end

          def dotenv_files(root, env)
            [
              File.join(root, ".env.#{env}.local"),
              (File.join(root, ".env.local") unless env == :test),
              File.join(root, ".env.#{env}"),
              File.join(root, ".env")
            ].compact
          end
        end
      end
    end
  end
end
