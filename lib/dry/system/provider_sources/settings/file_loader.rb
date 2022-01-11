# frozen_string_literal: true

require_relative "file_parser"

module Dry
  module System
    module ProviderSources
      module Settings
        class FileLoader
          def call(root, env)
            files(root, env).reduce({}) do |hash, file|
              hash.merge(parser.(file))
            end
          end

          private

          def parser
            @parser ||= FileParser.new
          end

          def files(root, env)
            [
              root.join(".env"),
              root.join(".env.#{env}")
            ].compact
          end
        end
      end
    end
  end
end
