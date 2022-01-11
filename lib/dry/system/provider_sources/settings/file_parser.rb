# frozen_string_literal: true

# TODO: Just update this to try dotenv and be done with it

module Dry
  module System
    module ProviderSources
      module Settings
        class FileParser
          # rubocop:disable Style/RedundantRegexpEscape

          # Regex extracted from dotenv gem
          # https://github.com/bkeepers/dotenv/blob/master/lib/dotenv/parser.rb#L14
          LINE = /
            \A
            \s*
            (?:export\s+)?    # optional export
            ([\w\.]+)         # key
            (?:\s*=\s*|:\s+?) # separator
            (                 # optional value begin
              '(?:\'|[^'])*'  #   single quoted value
              |               #   or
              "(?:\"|[^"])*"  #   double quoted value
              |               #   or
              [^#\n]+         #   unquoted value
            )?                # value end
            \s*
            (?:\#.*)?         # optional comment
            \z
          /x.freeze

          # rubocop:enable Style/RedundantRegexpEscape

          def call(file)
            File.readlines(file).each_with_object({}) do |line, hash|
              parse_line(line, hash)
            end
          rescue Errno::ENOENT
            {}
          end

          private

          def parse_line(line, hash)
            if (match = line.match(LINE))
              key, value = match.captures
              hash[key] = parse_value(value || "")
            end
            hash
          end

          def parse_value(value)
            value.strip.sub(/\A(['"])(.*)\1\z/, '\2')
          end
        end
      end
    end
  end
end
